-- Paraplan: bütçe satırı e-posta ile tekilleştirilir (aynı e-posta, Google veya şifre fark etmez).
-- Supabase SQL Editor'da sırayla çalıştırın. Eski policy isimlerinizi kendi projenize göre düzenleyin.

ALTER TABLE user_budget ADD COLUMN IF NOT EXISTS owner_email text;

UPDATE user_budget b
SET owner_email = lower(trim(u.email))
FROM auth.users u
WHERE u.id = b.user_id
  AND (b.owner_email IS NULL OR b.owner_email = '');

CREATE UNIQUE INDEX IF NOT EXISTS user_budget_owner_email_unique ON user_budget (owner_email);

-- RLS: mevcut user_id tabanlı policy'leri kaldırın (isimler projeye göre değişir), sonra:
-- ALTER TABLE user_budget ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own budget" ON user_budget;
DROP POLICY IF EXISTS "Users can insert own budget" ON user_budget;
DROP POLICY IF EXISTS "Users can update own budget" ON user_budget;
DROP POLICY IF EXISTS "Users can delete own budget" ON user_budget;

CREATE POLICY "budget_select_by_email" ON user_budget
  FOR SELECT TO authenticated
  USING (owner_email = lower(trim(auth.jwt() ->> 'email')));

CREATE POLICY "budget_insert_by_email" ON user_budget
  FOR INSERT TO authenticated
  WITH CHECK (owner_email = lower(trim(auth.jwt() ->> 'email')));

CREATE POLICY "budget_update_by_email" ON user_budget
  FOR UPDATE TO authenticated
  USING (owner_email = lower(trim(auth.jwt() ->> 'email')))
  WITH CHECK (owner_email = lower(trim(auth.jwt() ->> 'email')));

CREATE POLICY "budget_delete_by_email" ON user_budget
  FOR DELETE TO authenticated
  USING (owner_email = lower(trim(auth.jwt() ->> 'email')));
