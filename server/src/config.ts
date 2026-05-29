import 'dotenv/config';

export const config = {
  port:         parseInt(process.env.PORT ?? '3001', 10),
  clientOrigin: process.env.CLIENT_ORIGIN ?? 'http://localhost:8081',
  databaseUrl:  process.env.DATABASE_URL ?? '',
  redisUrl:     process.env.REDIS_URL ?? 'redis://localhost:6379',
  supabase: {
    url:        process.env.SUPABASE_URL ?? '',
    serviceKey: process.env.SUPABASE_SERVICE_KEY ?? '',
  },
  isDev: process.env.NODE_ENV !== 'production',
  tick: {
    rateMs:          50,     // 20 Hz
    countdownMs:     3000,   // 3s Countdown vor Match-Start
    botFillDelayMs:  10000,  // 10s warten, dann mit Bots auffuellen
  },
} as const;
