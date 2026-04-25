-- Schema Supabase para reuniões Gather capturadas via clickup@floridarentalcar.com.br
-- Rodar no SQL Editor do Supabase uma vez.

create extension if not exists "pgcrypto";

create table if not exists public.gather_meetings (
  id              uuid primary key default gen_random_uuid(),
  email_id        text unique not null,            -- Message-ID do Gmail (idempotência)
  thread_id       text,
  subject         text,
  from_address    text,
  meeting_title   text,
  meeting_date    timestamptz,
  duration_min    integer,
  attendees       jsonb default '[]'::jsonb,
  summary         text,
  action_items    jsonb default '[]'::jsonb,
  key_takeaways   jsonb default '[]'::jsonb,
  recording_url   text,
  transcript_url  text,
  space_name      text,
  raw_text        text,
  raw_html        text,
  received_at     timestamptz not null default now(),
  sent_to_telegram boolean not null default false,
  telegram_message_id text,
  telegram_chat_id    text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists gather_meetings_meeting_date_idx
  on public.gather_meetings (meeting_date desc);

create index if not exists gather_meetings_received_at_idx
  on public.gather_meetings (received_at desc);

create index if not exists gather_meetings_sent_idx
  on public.gather_meetings (sent_to_telegram) where sent_to_telegram = false;

create or replace function public.tg_gather_meetings_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists trg_gather_meetings_updated_at on public.gather_meetings;
create trigger trg_gather_meetings_updated_at
before update on public.gather_meetings
for each row execute function public.tg_gather_meetings_updated_at();

alter table public.gather_meetings enable row level security;

drop policy if exists "service_role_all" on public.gather_meetings;
create policy "service_role_all" on public.gather_meetings
  for all to service_role using (true) with check (true);
