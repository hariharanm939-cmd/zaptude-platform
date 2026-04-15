-- ============================================================
-- Zaptude / PlaceTrack — Complete Database Setup
-- Database: placement_db (PostgreSQL)
-- Instructions:
--   1. Open pgAdmin
--   2. Right-click Databases → Create → Database → name it: placement_db
--   3. Click placement_db → Tools → Query Tool
--   4. Paste this entire file and press F5
-- ============================================================


-- ── 1. Admins ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admins (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(100) UNIQUE NOT NULL,
  password   VARCHAR(255) NOT NULL,
  role       VARCHAR(20)  DEFAULT 'admin',
  created_at TIMESTAMP    DEFAULT NOW()
);


-- ── 2. Students ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id               SERIAL PRIMARY KEY,
  name             VARCHAR(100) NOT NULL,
  register_number  VARCHAR(50)  UNIQUE NOT NULL,
  email            VARCHAR(100) UNIQUE NOT NULL,
  password         VARCHAR(255),
  phone            VARCHAR(15),
  department       VARCHAR(100),
  cgpa             DECIMAL(3,2),
  arrears          INT          DEFAULT 0,
  placement_status VARCHAR(50)  DEFAULT 'not placed',
  role             VARCHAR(20)  DEFAULT 'student',
  created_at       TIMESTAMP    DEFAULT NOW()
);


-- ── 3. Student Skills ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_skills (
  id         SERIAL PRIMARY KEY,
  student_id INT REFERENCES students(id) ON DELETE CASCADE,
  skill_name VARCHAR(100),
  skill_type VARCHAR(50)
);


-- ── 4. Batches ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batches (
  id            SERIAL PRIMARY KEY,
  batch_name    VARCHAR(100) NOT NULL,
  batch_type    VARCHAR(50),
  description   TEXT,
  student_count INT          DEFAULT 0,
  created_at    TIMESTAMP    DEFAULT NOW()
);


-- ── 5. Batch Students ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batch_students (
  id         SERIAL PRIMARY KEY,
  batch_id   INT REFERENCES batches(id)  ON DELETE CASCADE,
  student_id INT REFERENCES students(id) ON DELETE CASCADE
);


-- ── 6. Topics ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS topics (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  category    VARCHAR(50)  CHECK (category IN ('quantitative','logical','verbal','programming','sql')),
  slug        VARCHAR(100) UNIQUE,
  order_index SMALLINT
);

-- Default 9 topics (safe to re-run — skips duplicates)
INSERT INTO topics (name, category, slug, order_index) VALUES
  ('Arithmetic',            'quantitative', 'arithmetic',            1),
  ('Percentages',           'quantitative', 'percentages',           2),
  ('Time & Work',           'quantitative', 'time-work',             3),
  ('Logical Reasoning',     'logical',      'logical-reasoning',     4),
  ('Blood Relations',       'logical',      'blood-relations',       5),
  ('Verbal Ability',        'verbal',       'verbal-ability',        6),
  ('Reading Comprehension', 'verbal',       'reading-comprehension', 7),
  ('Programming Basics',    'programming',  'programming-basics',    8),
  ('SQL Queries',           'sql',          'sql-queries',           9)
ON CONFLICT (slug) DO NOTHING;


-- ── 7. Question Bank ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS question_bank (
  id             SERIAL PRIMARY KEY,
  question_text  TEXT         NOT NULL,
  topic_id       INT REFERENCES topics(id),
  topic          VARCHAR(100),
  difficulty     VARCHAR(20)  CHECK (difficulty IN ('easy','medium','hard')),
  correct_option INT,
  explanation    TEXT,
  source         VARCHAR(20)  DEFAULT 'manual',
  options        JSONB,
  created_at     TIMESTAMP    DEFAULT NOW()
);


-- ── 8. Question Options ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS question_options (
  id            SERIAL PRIMARY KEY,
  question_id   INT REFERENCES question_bank(id) ON DELETE CASCADE,
  option_number INT,
  option_text   TEXT
);


-- ── 9. Tests ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tests (
  id               SERIAL PRIMARY KEY,
  test_name        VARCHAR(150) NOT NULL,
  test_type        VARCHAR(100),
  duration_minutes INT,
  total_marks      INT,
  negative_marking BOOLEAN      DEFAULT FALSE,
  scheduled_at     TIMESTAMP,
  created_at       TIMESTAMP    DEFAULT NOW()
);


-- ── 10. Test Questions (global pool per test) ─────────────────────────────
CREATE TABLE IF NOT EXISTS test_questions (
  id          SERIAL PRIMARY KEY,
  test_id     INT REFERENCES tests(id)         ON DELETE CASCADE,
  question_id INT REFERENCES question_bank(id) ON DELETE CASCADE,
  marks       INT DEFAULT 1
);


-- ── 11. Student Test Questions (personalized per student) ─────────────────
CREATE TABLE IF NOT EXISTS student_test_questions (
  id          SERIAL PRIMARY KEY,
  test_id     INT REFERENCES tests(id)         ON DELETE CASCADE,
  student_id  INT REFERENCES students(id)      ON DELETE CASCADE,
  question_id INT REFERENCES question_bank(id) ON DELETE CASCADE,
  marks       INT DEFAULT 1,
  UNIQUE (test_id, student_id, question_id)
);


-- ── 12. Test Assignments ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS test_assignments (
  id                   SERIAL PRIMARY KEY,
  test_id              INT REFERENCES tests(id)    ON DELETE CASCADE,
  student_id           INT REFERENCES students(id) ON DELETE CASCADE,
  assigned_at          TIMESTAMP DEFAULT NOW(),
  student_scheduled_at TIMESTAMP                        -- per-student retest override
);


-- ── 13. Student Test Attempts ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_test_attempts (
  id                    SERIAL PRIMARY KEY,
  student_id            INT REFERENCES students(id) ON DELETE CASCADE,
  test_id               INT REFERENCES tests(id)    ON DELETE CASCADE,
  score                 INT,
  total_questions       INT          DEFAULT 0,
  correct_answers       INT          DEFAULT 0,
  wrong_answers         INT          DEFAULT 0,
  time_taken_seconds    INT          DEFAULT 0,
  tab_switch_count      INT          DEFAULT 0,
  fullscreen_exit_count INT          DEFAULT 0,
  cheating_flag         BOOLEAN      DEFAULT FALSE,
  status                VARCHAR(20)  DEFAULT 'submitted',
  started_at            TIMESTAMP,
  attempted_at          TIMESTAMP    DEFAULT NOW()
);


-- ── 14. Student Answers ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_answers (
  id                 SERIAL PRIMARY KEY,
  attempt_id         INT REFERENCES student_test_attempts(id) ON DELETE CASCADE,
  question_id        INT REFERENCES question_bank(id),
  selected_option    INT,
  is_correct         BOOLEAN,
  time_spent_seconds INT
);


-- ── 15. Topic Performance ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS topic_performance (
  id                    SERIAL PRIMARY KEY,
  student_id            INT REFERENCES students(id) ON DELETE CASCADE,
  topic                 VARCHAR(100),
  total_questions       INT,
  correct_answers       INT,
  score_percentage      DECIMAL(5,2),
  avg_time_per_question DECIMAL(6,2),
  total_attempted       INT          DEFAULT 0,
  last_practiced_at     TIMESTAMP,
  updated_at            TIMESTAMP    DEFAULT NOW(),
  UNIQUE (student_id, topic)
);


-- ── 16. Readiness Scores ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS readiness_scores (
  id                SERIAL PRIMARY KEY,
  student_id        INT REFERENCES students(id) ON DELETE CASCADE,
  quant_score       DECIMAL(5,2) DEFAULT 0,
  logical_score     DECIMAL(5,2) DEFAULT 0,
  verbal_score      DECIMAL(5,2) DEFAULT 0,
  consistency_score DECIMAL(5,2) DEFAULT 0,
  overall_score     DECIMAL(5,2) DEFAULT 0,
  readiness_level   VARCHAR(30)  DEFAULT 'needs_improvement',
  computed_at       TIMESTAMP    DEFAULT NOW(),
  UNIQUE (student_id)
);


-- ── 17. Mistake Bank ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mistake_bank (
  id            SERIAL PRIMARY KEY,
  student_id    INT REFERENCES students(id)      ON DELETE CASCADE,
  question_id   INT REFERENCES question_bank(id) ON DELETE CASCADE,
  attempt_count INT          DEFAULT 1,
  last_seen_at  TIMESTAMP    DEFAULT NOW(),
  is_resolved   BOOLEAN      DEFAULT FALSE,
  UNIQUE (student_id, question_id)
);


-- ── 18. Leaderboard Snapshots ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
  id                SERIAL PRIMARY KEY,
  student_id        INT REFERENCES students(id) ON DELETE CASCADE,
  accuracy_score    DECIMAL(5,2) DEFAULT 0,
  speed_score       DECIMAL(5,2) DEFAULT 0,
  consistency_score DECIMAL(5,2) DEFAULT 0,
  total_score       DECIMAL(5,2) DEFAULT 0,
  rank              INT,
  snapshot_date     DATE         DEFAULT CURRENT_DATE
);


-- ── 19. Practice Sessions (Mock Test) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS practice_sessions (
  id                  SERIAL PRIMARY KEY,
  student_id          INT REFERENCES students(id) ON DELETE CASCADE,
  topic_id            INT REFERENCES topics(id),
  questions_attempted INT DEFAULT 0,
  correct_count       INT DEFAULT 0,
  time_spent_seconds  INT DEFAULT 0,
  created_at          TIMESTAMP DEFAULT NOW()
);


-- ── 20. Practice Answers ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS practice_answers (
  id                 SERIAL PRIMARY KEY,
  session_id         INT REFERENCES practice_sessions(id) ON DELETE CASCADE,
  question_id        INT REFERENCES question_bank(id),
  selected_answer    TEXT,
  is_correct         BOOLEAN,
  time_spent_seconds INT
);


-- ── 21. Retest Requests ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS retest_requests (
  id               SERIAL PRIMARY KEY,
  student_id       INT REFERENCES students(id) ON DELETE CASCADE,
  test_id          INT REFERENCES tests(id)    ON DELETE CASCADE,
  reason           TEXT,
  status           VARCHAR(20)  DEFAULT 'pending',  -- pending | approved | rejected
  requested_at     TIMESTAMP    DEFAULT NOW(),
  reviewed_at      TIMESTAMP,
  new_scheduled_at TIMESTAMP,
  admin_note       TEXT,
  UNIQUE (student_id, test_id)
);


-- ── 22. Admin Notifications ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_notifications (
  id         SERIAL PRIMARY KEY,
  type       VARCHAR(50),   -- e.g. 'retest_request'
  title      TEXT,
  message    TEXT,
  ref_id     INT,           -- references retest_requests.id
  is_read    BOOLEAN        DEFAULT FALSE,
  created_at TIMESTAMP      DEFAULT NOW()
);


-- ============================================================
-- DEFAULT BATCHES  (12 pre-seeded — safe to re-run)
-- ============================================================
INSERT INTO batches (batch_name, batch_type, description) VALUES
  ('No Arrears',         'auto', 'Students with zero arrears'),
  ('1-2 Arrears',        'auto', 'Students with 1 to 2 arrears'),
  ('3+ Arrears',         'auto', 'Students with 3 or more arrears'),
  ('High Performers',    'auto', 'Students with CGPA 8.0 and above'),
  ('Average Performers', 'auto', 'Students with CGPA 6.0 to 7.9'),
  ('Needs Improvement',  'auto', 'Students with CGPA below 6.0'),
  ('CSE Department',     'auto', 'Computer Science and Engineering'),
  ('ECE Department',     'auto', 'Electronics and Communication Engineering'),
  ('EEE Department',     'auto', 'Electrical and Electronics Engineering'),
  ('IT Department',      'auto', 'Information Technology'),
  ('MECH Department',    'auto', 'Mechanical Engineering'),
  ('CIVIL Department',   'auto', 'Civil Engineering')
ON CONFLICT DO NOTHING;


-- ============================================================
-- VERIFY — run this after to confirm all 22 tables exist
-- ============================================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

---

### Step 3 — Create `.env.example` file

Create `server/.env.example` — this IS pushed to GitHub so teammates know what to fill:
```
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=placement_db
DB_USER=postgres
DB_PASSWORD=your_password_here
JWT_SECRET=your_secret_key_here