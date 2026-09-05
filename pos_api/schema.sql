-- Matches lib/core/database/db_helper.dart exactly.
-- Run this once against your XAMPP / InfinityFree / Hostinger MySQL database.

CREATE TABLE IF NOT EXISTS users (
  uuid CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(32),
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_users_last_updated (last_updated)
);

CREATE TABLE IF NOT EXISTS businesses (
  uuid CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(64) NOT NULL,
  logo_path VARCHAR(255),
  owner_uuid CHAR(36) NOT NULL,
  zakat_nisab_threshold DECIMAL(14,2) NOT NULL DEFAULT 0,
  zakat_start_date BIGINT NULL,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_businesses_last_updated (last_updated),
  FOREIGN KEY (owner_uuid) REFERENCES users(uuid)
);

CREATE TABLE IF NOT EXISTS business_users (
  uuid CHAR(36) PRIMARY KEY,
  business_uuid CHAR(36) NOT NULL,
  user_uuid CHAR(36) NOT NULL,
  role VARCHAR(32) NOT NULL,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uniq_business_user (business_uuid, user_uuid),
  INDEX idx_bu_last_updated (last_updated),
  INDEX idx_bu_business (business_uuid),
  FOREIGN KEY (business_uuid) REFERENCES businesses(uuid),
  FOREIGN KEY (user_uuid) REFERENCES users(uuid)
);

-- NOTE (security): password_hash here is the SAME sha256+pepper hash the
-- app computes locally (see lib/core/utils/password_helper.dart). For a
-- production launch, re-hash server-side with password_hash()/bcrypt
-- instead of trusting the client's hash as the canonical stored value —
-- Phase 1 keeps it simple and consistent across offline/online so the
-- sync layer's job stays purely "move rows", not "manage two different
-- password schemes."

-- ============================================================================
-- PHASE 2 — matches lib/core/database/db_helper.dart _createPhase2Tables()
-- exactly, same as the Phase 1 tables above.
-- ============================================================================

CREATE TABLE IF NOT EXISTS items (
  uuid CHAR(36) PRIMARY KEY,
  business_uuid CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(128),
  barcode VARCHAR(128),
  purchase_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  sale_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_items_last_updated (last_updated),
  INDEX idx_items_business (business_uuid),
  INDEX idx_items_barcode (barcode),
  FOREIGN KEY (business_uuid) REFERENCES businesses(uuid)
);

CREATE TABLE IF NOT EXISTS customers (
  uuid CHAR(36) PRIMARY KEY,
  business_uuid CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(32),
  opening_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  current_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_customers_last_updated (last_updated),
  INDEX idx_customers_business (business_uuid),
  FOREIGN KEY (business_uuid) REFERENCES businesses(uuid)
);

CREATE TABLE IF NOT EXISTS sales (
  uuid CHAR(36) PRIMARY KEY,
  business_uuid CHAR(36) NOT NULL,
  customer_uuid CHAR(36) NULL,
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  due_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_sales_last_updated (last_updated),
  INDEX idx_sales_business (business_uuid),
  INDEX idx_sales_created (created_at),
  FOREIGN KEY (business_uuid) REFERENCES businesses(uuid),
  FOREIGN KEY (customer_uuid) REFERENCES customers(uuid)
);

CREATE TABLE IF NOT EXISTS sale_items (
  uuid CHAR(36) PRIMARY KEY,
  business_uuid CHAR(36) NOT NULL,
  sale_uuid CHAR(36) NOT NULL,
  item_uuid CHAR(36) NULL,
  item_name_snapshot VARCHAR(255) NOT NULL,
  unit_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
  line_total DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  last_updated BIGINT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_sale_items_last_updated (last_updated),
  INDEX idx_sale_items_sale (sale_uuid),
  FOREIGN KEY (sale_uuid) REFERENCES sales(uuid),
  FOREIGN KEY (item_uuid) REFERENCES items(uuid)
);
