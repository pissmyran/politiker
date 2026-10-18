-- D1-schema för politiker, läst från sqlite_master 2026-10-16. Endast struktur, ingen data.

CREATE TABLE account_contact_list_members (
  account_id TEXT NOT NULL,
  list_id TEXT NOT NULL,
  contact_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY(account_id, list_id, contact_id),
  FOREIGN KEY(list_id, account_id) REFERENCES account_contact_lists(id, account_id) ON DELETE CASCADE,
  FOREIGN KEY(contact_id, account_id) REFERENCES account_contacts(id, account_id) ON DELETE CASCADE
);

CREATE TABLE account_contact_lists (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL COLLATE NOCASE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(account_id, name),
  UNIQUE(id, account_id)
);

CREATE TABLE account_contacts (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  email TEXT NOT NULL COLLATE NOCASE,
  name TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(account_id, email),
  UNIQUE(id, account_id)
);

CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  email_verified INTEGER NOT NULL DEFAULT 0,
  verification_code TEXT,
  verification_expires_at INTEGER,
  daily_send_cap INTEGER NOT NULL DEFAULT 200,
  created_at INTEGER NOT NULL
, is_admin INTEGER NOT NULL DEFAULT 0, reset_token TEXT, reset_expires_at INTEGER, totp_secret TEXT, totp_enabled INTEGER NOT NULL DEFAULT 0, disabled INTEGER NOT NULL DEFAULT 0, password_set_by_user INTEGER NOT NULL DEFAULT 0);

CREATE TABLE api_keys (id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id), key_hash TEXT NOT NULL UNIQUE, name TEXT NOT NULL, created_at INTEGER NOT NULL, last_used_at INTEGER);

CREATE TABLE campaign_recipients (
            id TEXT PRIMARY KEY,
            draft_id TEXT NOT NULL,
            politician_id TEXT NOT NULL,
            politician_email TEXT NOT NULL,
            politician_name TEXT NOT NULL,
            area_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            sent_at INTEGER,
            error TEXT
        );

CREATE TABLE client_errors (
  signature TEXT PRIMARY KEY,
  message TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 1,
  first_seen INTEGER NOT NULL,
  last_seen INTEGER NOT NULL,
  github_issue_url TEXT
, email_notified_at INTEGER);

CREATE TABLE d1_migrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    );

CREATE TABLE feedback (
  id TEXT PRIMARY KEY,
  account_id TEXT,
  message TEXT NOT NULL,
  github_issue_url TEXT,
  created_at INTEGER NOT NULL
, reply_to TEXT, wants_reply INTEGER NOT NULL DEFAULT 0, kind TEXT NOT NULL DEFAULT 'feedback');

CREATE TABLE letter_attachments (id TEXT PRIMARY KEY, letter_id TEXT NOT NULL REFERENCES letters(id), filename TEXT NOT NULL, content_type TEXT NOT NULL, r2_key TEXT NOT NULL, size_bytes INTEGER NOT NULL, mode TEXT NOT NULL, created_at INTEGER NOT NULL);

CREATE TABLE letter_intro_presets (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 80),
  body_text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE letters (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id),
  html_body TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE mail_credentials (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id),
  provider TEXT NOT NULL,
  smtp_host TEXT NOT NULL,
  smtp_port INTEGER NOT NULL,
  smtp_user TEXT NOT NULL,
  encrypted_password TEXT NOT NULL,
  from_address TEXT NOT NULL,
  verified_at INTEGER,
  created_at INTEGER NOT NULL
, daily_cap INTEGER, oauth_access_token TEXT, oauth_refresh_token TEXT, oauth_token_expires_at INTEGER, user_cap_pct INTEGER NOT NULL DEFAULT 100, revoked_at INTEGER);

CREATE TABLE monitored_items (
            id TEXT PRIMARY KEY,
            source TEXT NOT NULL,
            item_type TEXT NOT NULL,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            area_name TEXT,
            area_type TEXT,
            summary TEXT,
            published_at INTEGER,
            created_at INTEGER NOT NULL,
            letter_queued INTEGER NOT NULL DEFAULT 0
        );

CREATE TABLE oauth_identities (id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id), provider TEXT NOT NULL, provider_user_id TEXT NOT NULL, created_at INTEGER NOT NULL, provider_email TEXT, UNIQUE(provider, provider_user_id));

CREATE TABLE "public_contacts" (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  area_name TEXT NOT NULL,
  area_type TEXT NOT NULL,
  last_scraped_at INTEGER NOT NULL, verification_status TEXT NOT NULL DEFAULT 'unknown', last_verified_at INTEGER, party TEXT, role TEXT, organisation TEXT, unit TEXT, title TEXT, academic_field TEXT, source_url TEXT,
  UNIQUE(email, area_name)
);

CREATE TABLE "public_contact_assignments" (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  contact_id TEXT NOT NULL REFERENCES "public_contacts"(id) ON DELETE CASCADE,
  area_name TEXT NOT NULL,
  body TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT '',
  source TEXT,
  last_scraped_at INTEGER NOT NULL,
  UNIQUE(contact_id, body, role)
);

CREATE TABLE send_jobs (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts(id),
  letter_id TEXT NOT NULL REFERENCES letters(id),
  mail_credential_id TEXT NOT NULL REFERENCES mail_credentials(id),
  total_recipients INTEGER NOT NULL,
  sent_count INTEGER NOT NULL DEFAULT 0,
  bounce_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at INTEGER NOT NULL,
  finished_at INTEGER
, daily_limit INTEGER, next_daily_limit INTEGER, limit_switch_at INTEGER, content_retention_ms INTEGER NOT NULL DEFAULT 300000, content_delete_at INTEGER, intro_text TEXT);

CREATE TABLE send_job_recipients (
  send_job_id TEXT NOT NULL REFERENCES send_jobs(id) ON DELETE CASCADE,
  recipient_email TEXT NOT NULL COLLATE NOCASE,
  recipient_name TEXT NOT NULL,
  subject TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  queued_at INTEGER,
  finished_at INTEGER,
  error TEXT,
  PRIMARY KEY (send_job_id, recipient_email)
);

CREATE TABLE send_log (
  id TEXT PRIMARY KEY,
  send_job_id TEXT NOT NULL REFERENCES send_jobs(id),
  account_id TEXT NOT NULL REFERENCES accounts(id),
  recipient_email TEXT NOT NULL,
  status TEXT NOT NULL,
  error TEXT,
  sent_at INTEGER NOT NULL
);

CREATE TABLE visits (
  id TEXT PRIMARY KEY,
  visitor_hash TEXT NOT NULL,
  visited_at INTEGER NOT NULL
, country TEXT);

CREATE TABLE worker_errors (id TEXT PRIMARY KEY, account_id TEXT, method TEXT NOT NULL, endpoint TEXT NOT NULL, status INTEGER NOT NULL, error_message TEXT NOT NULL, created_at INTEGER NOT NULL);

CREATE INDEX idx_account_contact_members_contact ON account_contact_list_members(account_id, contact_id);

CREATE INDEX idx_camp_rec_status ON campaign_recipients(status);

CREATE INDEX idx_client_errors_email_notified_at
  ON client_errors (email_notified_at);

CREATE INDEX idx_client_errors_first_seen ON client_errors (first_seen);

CREATE INDEX idx_letter_intro_presets_account
  ON letter_intro_presets(account_id, created_at);

CREATE INDEX idx_mail_credentials_account_active
  ON mail_credentials(account_id, revoked_at, created_at);

CREATE UNIQUE INDEX idx_oauth_identities_account_provider ON oauth_identities(account_id, provider);

CREATE INDEX idx_public_contact_assignments_area_body ON public_contact_assignments(area_name, body);

CREATE INDEX idx_public_contact_assignments_contact ON public_contact_assignments(contact_id);

CREATE INDEX idx_public_contacts_academic_field ON public_contacts(area_type, academic_field);

CREATE INDEX idx_public_contacts_area ON public_contacts(area_type, area_name);

CREATE INDEX idx_public_contacts_area_role ON public_contacts(area_name, role);

CREATE INDEX idx_public_contacts_email_normalized ON public_contacts(lower(trim(email)));

CREATE INDEX idx_public_contacts_role ON public_contacts(role);

CREATE INDEX idx_send_job_recipients_pending
  ON send_job_recipients(send_job_id, status);

CREATE INDEX idx_send_job_recipients_queued
  ON send_job_recipients(status, queued_at);

CREATE INDEX idx_send_jobs_account_created
  ON send_jobs(account_id, created_at DESC);

CREATE INDEX idx_send_jobs_mail_credential
  ON send_jobs(mail_credential_id);

CREATE INDEX idx_send_jobs_status_created
  ON send_jobs(status, created_at);

CREATE INDEX idx_send_log_account_date ON send_log(account_id, sent_at);

CREATE INDEX idx_send_log_job_date_status
  ON send_log(send_job_id, sent_at, status);

CREATE INDEX idx_visits_hash ON visits(visitor_hash);

CREATE INDEX idx_visits_visited_at ON visits(visited_at);

CREATE INDEX idx_worker_errors_account ON worker_errors(account_id, created_at);

CREATE TRIGGER account_contacts_cap_insert
BEFORE INSERT ON account_contacts
WHEN NOT EXISTS (
  SELECT 1 FROM account_contacts
  WHERE account_id = NEW.account_id AND email = NEW.email COLLATE NOCASE
)
AND (
  SELECT COUNT(*) FROM account_contacts WHERE account_id = NEW.account_id
) >= 10000
BEGIN
  SELECT RAISE(ABORT, 'Kontot kan ha högst 10000 sparade mottagare');
END;

CREATE TRIGGER accounts_email_nocase_insert
BEFORE INSERT ON accounts
WHEN EXISTS (
  SELECT 1 FROM accounts
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(NEW.email))
)
BEGIN
  SELECT RAISE(ABORT, 'E-postadressen är redan registrerad');
END;

CREATE TRIGGER accounts_email_nocase_update
BEFORE UPDATE OF email ON accounts
WHEN EXISTS (
  SELECT 1 FROM accounts
  WHERE id <> OLD.id
    AND LOWER(TRIM(email)) = LOWER(TRIM(NEW.email))
)
BEGIN
  SELECT RAISE(ABORT, 'E-postadressen är redan registrerad');
END;

CREATE TRIGGER disable_totp_after_password_reset
AFTER UPDATE OF reset_token ON accounts
WHEN OLD.reset_token IS NOT NULL AND NEW.reset_token IS NULL
BEGIN
  UPDATE accounts
  SET totp_enabled = 0,
      totp_secret = NULL
  WHERE id = NEW.id;
END;

CREATE TRIGGER trg_send_jobs_clear_content_retention
AFTER UPDATE OF status ON send_jobs
WHEN NEW.status IN ('pending','sending') AND OLD.status != NEW.status
BEGIN
  UPDATE send_jobs SET content_delete_at = NULL WHERE id = NEW.id;
END;

CREATE TRIGGER trg_send_jobs_content_retention
AFTER UPDATE OF status, finished_at ON send_jobs
WHEN NEW.finished_at IS NOT NULL
 AND NEW.status IN ('done','aborted','cancelled')
BEGIN
  UPDATE send_jobs
  SET content_delete_at = NEW.finished_at +
    CASE NEW.content_retention_ms
      WHEN 300000 THEN 300000
      WHEN 86400000 THEN 86400000
      WHEN 259200000 THEN 259200000
      WHEN 604800000 THEN 604800000
      ELSE 300000
    END
  WHERE id = NEW.id;
END;
