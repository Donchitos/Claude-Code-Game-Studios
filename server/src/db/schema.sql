-- BRAWLZONE — Supabase Schema (canonical)
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- Replaces the legacy `profiles` table with `player_profiles`.

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYER PROFILES (canonical — extends auth.users 1:1)
-- Canonical source: server/src/profile/playerProfileService.ts
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.player_profiles (
  user_id                     uuid primary key references auth.users(id) on delete cascade,
  display_name                text not null,
  display_name_last_changed_at timestamptz,
  avatar_id                   text not null default 'default_avatar',
  region                      text not null default 'auto',
  created_at                  timestamptz not null default now(),
  last_seen_at                timestamptz not null default now(),
  -- Match stats
  total_matches               integer not null default 0 check (total_matches >= 0),
  wins                        integer not null default 0 check (wins >= 0),
  losses                      integer not null default 0 check (losses >= 0),
  kills                       integer not null default 0 check (kills >= 0),
  preferred_character_id      text,
  -- MMR
  mmr                         integer not null default 1000 check (mmr >= 0),
  peak_mmr                    integer not null default 1000 check (peak_mmr >= 0),
  is_provisional              boolean not null default true,
  provisional_match_count     integer not null default 0,
  -- Economy
  coin_balance                integer not null default 0 check (coin_balance >= 0),
  diamond_balance             integer not null default 0 check (diamond_balance >= 0),
  has_no_ads                  boolean not null default false,
  has_play_pass               boolean not null default false,
  -- Progression
  xp                          integer not null default 0 check (xp >= 0),
  level                       integer not null default 1 check (level >= 1),
  unlocked_character_ids      jsonb not null default '["character:vex","character:zook","character:sera"]',
  -- Consent + soft delete
  analytics_consent           boolean not null default true,
  is_deleted                  boolean not null default false,

  constraint display_name_length check (char_length(display_name) between 3 and 20),
  constraint display_name_chars  check (display_name ~ '^[A-Za-z0-9_-]+$'),
  unique (display_name)
);

-- Auto-create profile on Supabase signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  v_name text;
begin
  v_name := coalesce(
    new.raw_user_meta_data->>'username',
    'Player_' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6))
  );
  insert into public.player_profiles (user_id, display_name)
  values (new.id, v_name)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- ENTITLEMENTS — owned items (characters, cosmetics, battle pass)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.entitlements (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  item_id          text not null,                  -- e.g. "character:vex", "skin:vex_fire"
  idempotency_key  text not null unique,
  granted_at       timestamptz not null default now(),
  unique (user_id, item_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ECONOMY TRANSACTIONS — idempotent ledger (coins + diamonds)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.economy_transactions (
  id               uuid primary key default gen_random_uuid(),
  idempotency_key  text not null unique,
  user_id          uuid not null references auth.users(id) on delete cascade,
  source           text not null,                  -- e.g. "match_reward", "iap_pack"
  coin_delta       integer not null default 0,
  diamond_delta    integer not null default 0,
  final_coins      integer,                         -- snapshot after update
  final_diamonds   integer,
  created_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHARACTER XP — per-character progression
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.character_xp (
  user_id       uuid not null references auth.users(id) on delete cascade,
  character_id  text not null,
  xp            integer not null default 0 check (xp >= 0),
  primary key (user_id, character_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- XP GRANTS — idempotent XP award ledger
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.xp_grants (
  id               uuid primary key default gen_random_uuid(),
  idempotency_key  text not null unique,
  user_id          uuid not null references auth.users(id) on delete cascade,
  source           text not null,                  -- e.g. "match_end", "quest_complete"
  player_xp        integer not null default 0,
  character_xp     integer not null default 0,
  character_id     text,
  created_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- AD TOKENS — free-player ad watch tracking (1 token = 1 ad watched)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.ad_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  token_type  text not null default 'ad_watch',
  used_at     timestamptz not null default now(),
  reward_type text,                                -- e.g. "coins_100", "chest_common"
  reward_ref  text                                 -- idempotency key of the economy transaction
);

-- ─────────────────────────────────────────────────────────────────────────────
-- MATCH RECORDS — completed match log
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.match_records (
  id           uuid primary key default gen_random_uuid(),
  mode         text not null check (mode in ('duel_1v1', 'squad_3v3', 'ffa_8')),
  status       text not null default 'active' check (status in ('active', 'finished', 'aborted')),
  started_at   timestamptz not null default now(),
  ended_at     timestamptz,
  duration_s   integer check (duration_s >= 0)
);

create table if not exists public.match_participants (
  id               uuid primary key default gen_random_uuid(),
  match_id         uuid not null references public.match_records(id) on delete cascade,
  user_id          uuid not null references auth.users(id),
  character_id     text not null,
  score            integer not null default 0,
  kills            integer not null default 0,
  damage_dealt     integer not null default 0,
  xp_gained        integer not null default 0,
  coins_gained     integer not null default 0,
  placement        integer,
  is_winner        boolean not null default false,
  disconnected     boolean not null default false,
  unique (match_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.player_profiles    enable row level security;
alter table public.entitlements       enable row level security;
alter table public.economy_transactions enable row level security;
alter table public.character_xp       enable row level security;
alter table public.xp_grants          enable row level security;
alter table public.ad_tokens          enable row level security;
alter table public.match_records      enable row level security;
alter table public.match_participants enable row level security;

-- player_profiles: users read their own; service role writes
create policy "profile_select_own"
  on public.player_profiles for select
  using (auth.uid() = user_id);

create policy "profile_update_own"
  on public.player_profiles for update
  using (auth.uid() = user_id);

-- entitlements: users read their own
create policy "entitlement_select_own"
  on public.entitlements for select
  using (auth.uid() = user_id);

-- economy_transactions: users read their own
create policy "economy_tx_select_own"
  on public.economy_transactions for select
  using (auth.uid() = user_id);

-- character_xp: users read their own
create policy "character_xp_select_own"
  on public.character_xp for select
  using (auth.uid() = user_id);

-- xp_grants: users read their own
create policy "xp_grants_select_own"
  on public.xp_grants for select
  using (auth.uid() = user_id);

-- ad_tokens: users read their own
create policy "ad_tokens_select_own"
  on public.ad_tokens for select
  using (auth.uid() = user_id);

-- match_participants: users read their own match history
create policy "match_participants_select_own"
  on public.match_participants for select
  using (auth.uid() = user_id);

-- match_records: public read (match metadata is not sensitive)
create policy "match_records_select_all"
  on public.match_records for select
  using (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────────────────────────────────────
create index if not exists idx_entitlements_user_id    on public.entitlements (user_id);
create index if not exists idx_economy_tx_user_id      on public.economy_transactions (user_id);
create index if not exists idx_match_participants_user on public.match_participants (user_id);
create index if not exists idx_match_participants_match on public.match_participants (match_id);
create index if not exists idx_ad_tokens_user_id       on public.ad_tokens (user_id);
