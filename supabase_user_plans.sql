-- Paraplan: Pro / Lifetime üyelik satırı (e-posta ile user_budget ile aynı anahtar)
-- Supabase SQL Editor'da çalıştırın. Gumroad webhook veya manuel INSERT ile doldurulur.

CREATE TABLE IF NOT EXISTS user_plans (
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  owner_email text NOT NULL,
  tier text NOT NULL CHECK (tier IN ('free', 'pro', 'lifetime')),
  valid_until timestamptz,
  license_ref text,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (owner_email)
);

CREATE UNIQUE INDEX IF NOT EXISTS user_plans_user_id_unique ON user_plans (user_id);

ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plans_select_own" ON user_plans;
CREATE POLICY "plans_select_own" ON user_plans
  FOR SELECT TO authenticated
  USING (owner_email = lower(trim(auth.jwt() ->> 'email')));

-- İstemci yazmasın: tier Gumroad Edge Function / service role ile güncellenir.
-- Mevcut user_budget kullanıcılarını geçici olarak Pro yapmak (bir kerelik):
-- INSERT INTO user_plans (user_id, owner_email, tier, valid_until)
-- SELECT b.user_id, b.owner_email, 'pro', NULL
-- FROM user_budget b
-- WHERE b.owner_email IS NOT NULL AND trim(b.owner_email) <> ''
-- ON CONFLICT (owner_email) DO UPDATE SET tier = 'pro', updated_at = now();

-- Tek kullanıcı test:
-- INSERT INTO user_plans (user_id, owner_email, tier, valid_until)
-- SELECT id, lower(trim(email)), 'pro', null FROM auth.users WHERE email = 'siz@ornek.com'
-- ON CONFLICT (owner_email) DO UPDATE SET tier = excluded.tier, updated_at = now();
