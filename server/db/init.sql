-- Sweepy Organizer Database Schema

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  authentik_group_id TEXT NOT NULL,
  total_points INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_completed_date DATE,
  daily_effort_limit INT NOT NULL DEFAULT 6,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT 'home',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  household_id TEXT NOT NULL,
  name TEXT NOT NULL,
  difficulty INT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
  frequency_days INT NOT NULL DEFAULT 7,
  last_completed_at TIMESTAMPTZ,
  last_completed_by UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE task_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
  task_name TEXT NOT NULL,
  room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
  household_id TEXT NOT NULL,
  completed_by UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  completed_by_name TEXT NOT NULL,
  points_earned INT NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_profiles_group ON user_profiles(authentik_group_id);
CREATE INDEX idx_rooms_household ON rooms(household_id);
CREATE INDEX idx_tasks_household ON tasks(household_id);
CREATE INDEX idx_tasks_room ON tasks(room_id);
CREATE INDEX idx_task_logs_household ON task_logs(household_id);
CREATE INDEX idx_task_logs_completed_at ON task_logs(completed_at DESC);
CREATE INDEX idx_task_logs_completed_by ON task_logs(completed_by);
