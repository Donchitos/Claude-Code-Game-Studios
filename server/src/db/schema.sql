-- BRAWLZONE — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query

-- ─────────────────────────────────────────────
-- PROFILES (extends auth.users 1:1)
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text not null unique,
  avatar_url    text,
  rating        integer not null default 1000,
  diamonds      integer not null default 0,
  xp            integer not null default 0,
  has_no_ads    boolean not null default false,
  has_play_pass boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─────────────────────────────────────────────
-- MATCHES
-- ─────────────────────────────────────────────
create table if not exists public.matches (
  id          uuid primary key default gen_random_uuid(),
  mode        text not null check (mode in ('1v1', '3v3', 'ffa')),
  status      text not null default 'active' check (status in ('active', 'finished', 'aborted')),
  winner_id   uuid references auth.users(id),
  started_at  timestamptz not null default now(),
  ended_at    timestamptz,
  duration_s  integer
);

create table if not exists public.match_players (
  id              uuid primary key default gen_random_uuid(),
  match_id        uuid not null references public.matches(id) on delete cascade,
  user_id         uuid not null references auth.users(id),
  character_id    text not null,
  score           integer not null default 0,
  xp_gained       integer not null default 0,
  diamonds_gained integer not null default 0,
  placement       integer,
  disconnected    boolean not null default false,
  unique(match_id, user_id)
);

-- ─────────────────────────────────────────────
-- ECONOMY — IAP purchases log
-- ─────────────────────────────────────────────
create table if not exists public.purchases (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id),
  product_id          text not null,   -- RevenueCat product ID
  transaction_id      text not null unique,
  diamonds_granted    integer not null default 0,
  created_at          timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- BETA — IP tagging + Founder rewards
-- ─────────────────────────────────────────────
create table if not exists public.beta_registrations (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null unique references auth.users(id),
  registration_ip     inet not null,
  country_code        text,
  founder_skin_sent   boolean not null default false,
  discount_code       text,
  registered_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────
alter table public.profiles          enable row level security;
alter table public.matches           enable row level security;
alter table public.match_players     enable row level security;
alter table public.purchases         enable row level security;
alter table public.beta_registrations enable row level security;

-- profiles: users read own, service role writes
create policy "users_read_own_profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "users_update_own_profile"
  on public.profiles for update
  using (auth.uid() = id);

-- match_players: users read their own match history
create policy "users_read_own_matches"
  on public.match_players for select
  using (auth.uid() = user_id);

-- purchases: users read own
create policy "users_read_own_purchases"
  on public.purchases for select
  using (auth.uid() = user_id);

-- beta_registrations: users read own
create policy "users_read_own_beta"
  on public.beta_registrations for select
  using (auth.uid() = user_id);
