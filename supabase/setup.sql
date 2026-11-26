-- 새 투표용 테이블. 기존 투표는 이관하지 않습니다.
begin;
create extension if not exists pgcrypto with schema extensions;
create table if not exists public.mma_votes(name text primary key, answers jsonb not null, updated_at timestamptz not null default now());
create table if not exists public.mma_config(id boolean primary key check(id), password_hash text not null, token_hash text not null);
alter table public.mma_votes enable row level security;
alter table public.mma_config enable row level security;
revoke all on public.mma_votes,public.mma_config from public,anon,authenticated;
-- 아래 비밀번호를 변경한 후 실행하세요. 토큰은 자동 생성됩니다.

create or replace function public.mma_submit(p_name text,p_token text,p_answers jsonb) returns boolean language plpgsql security definer set search_path='' as $$
declare section jsonb; a jsonb;
begin
if p_token is null or length(p_token)<>64 or not exists(select 1 from public.mma_config where token_hash=encode(extensions.digest(p_token,'sha256'),'hex')) then raise exception 'invalid access'; end if;
if p_name is null or p_name not in ('새벽','씅','너아','유니','블체','허브','춘식','조록매실','위리놈') then raise exception 'invalid member'; end if;
if p_answers is null or jsonb_typeof(p_answers)<>'array' or length(p_answers::text)>30000 then raise exception 'invalid ballot'; end if;
if jsonb_array_length(p_answers)<>8 then raise exception 'invalid ballot'; end if;
for section in select value from jsonb_array_elements(p_answers) loop
if jsonb_typeof(section)<>'array' then raise exception 'invalid section'; end if;
if jsonb_array_length(section)>2 then raise exception 'too many votes'; end if;
for a in select value from jsonb_array_elements(section) loop
if jsonb_typeof(a->'choice') is distinct from 'string' or jsonb_typeof(a->'comment') is distinct from 'string' or length(a->>'choice')>1000 or length(a->>'comment')>500 or trim(a->>'choice')='' then raise exception 'invalid answer'; end if;
end loop;
if (select count(distinct x->>'choice') from jsonb_array_elements(section) x)<>jsonb_array_length(section) then raise exception 'duplicate'; end if;
end loop;
if not exists(select 1 from jsonb_array_elements(p_answers) x where jsonb_array_length(x)>0) then raise exception 'empty ballot'; end if;
insert into public.mma_votes(name,answers) values(p_name,p_answers) on conflict(name) do update set answers=excluded.answers,updated_at=now() where public.mma_votes.updated_at<now()-interval '10 seconds';
if not found then raise exception 'retry later'; end if;
return true;end;$$;
create or replace function public.mma_read(p_password text) returns jsonb language plpgsql security definer set search_path='' as $$
begin
if p_password is null or length(p_password)>72 or not exists(select 1 from public.mma_config where password_hash=extensions.crypt(p_password,password_hash)) then raise exception 'invalid password'; end if;
return (select coalesce(jsonb_agg(to_jsonb(v)),'[]'::jsonb) from public.mma_votes v);end;$$;
revoke all on function public.mma_submit(text,text,jsonb),public.mma_read(text) from public,anon,authenticated;
grant execute on function public.mma_submit(text,text,jsonb),public.mma_read(text) to anon,authenticated;
-- 이전 버전의 공개 RPC 차단 (존재하는 경우)
do $$ begin
if to_regprocedure('public.submit_award_vote(text,jsonb)') is not null then execute 'revoke all on function public.submit_award_vote(text,jsonb) from public,anon,authenticated'; end if;
if to_regprocedure('public.submit_award_vote_secure(text,text,jsonb)') is not null then execute 'revoke all on function public.submit_award_vote_secure(text,text,jsonb) from public,anon,authenticated'; end if;
if to_regprocedure('public.read_award_votes(text)') is not null then execute 'revoke all on function public.read_award_votes(text) from public,anon,authenticated'; end if;
end $$;
commit;
-- Generate and store the token in one statement, then return the link.
with generated as materialized (select encode(extensions.gen_random_bytes(32),'hex') as token),
saved as (
 insert into public.mma_config(id,password_hash,token_hash)
 select true,extensions.crypt('CHANGE_THIS_PASSWORD',extensions.gen_salt('bf',12)),encode(extensions.digest(token,'sha256'),'hex') from generated
 on conflict(id) do update set password_hash=excluded.password_hash,token_hash=excluded.token_hash
 returning id
)
select 'https://1lkahy.github.io/MMA/#token='||generated.token as private_vote_link from generated cross join saved;
