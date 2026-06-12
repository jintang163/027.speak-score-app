CREATE DATABASE IF NOT EXISTS speak_score
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE speak_score;

CREATE TABLE sys_role (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_code   VARCHAR(30)  NOT NULL UNIQUE,
    role_name   VARCHAR(50)  NOT NULL,
    description VARCHAR(200),
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     BIT(1)       NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sys_user (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    username           VARCHAR(50),
    password           VARCHAR(200),
    nickname           VARCHAR(50),
    real_name          VARCHAR(50),
    avatar             VARCHAR(500),
    phone              VARCHAR(20) UNIQUE,
    wechat_openid      VARCHAR(100) UNIQUE,
    wechat_unionid     VARCHAR(100),
    gender             INT,
    enabled            BIT(1)       NOT NULL DEFAULT 1,
    account_non_locked BIT(1)       NOT NULL DEFAULT 1,
    class_id           BIGINT,
    school_id          BIGINT,
    created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted            BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_phone (phone),
    INDEX idx_openid (wechat_openid),
    INDEX idx_class (class_id),
    INDEX idx_school (school_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sys_user_role (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES sys_user(id),
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES sys_role(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sys_permission (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    permission_code VARCHAR(80)  NOT NULL UNIQUE,
    permission_name VARCHAR(100) NOT NULL,
    resource_type   VARCHAR(20),
    resource_path   VARCHAR(200),
    method          VARCHAR(10),
    parent_id       BIGINT,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_code (permission_code),
    CONSTRAINT fk_permission_parent FOREIGN KEY (parent_id) REFERENCES sys_permission(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sys_role_permission (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id       BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted       BIT(1)   NOT NULL DEFAULT 0,
    UNIQUE KEY uk_role_perm (role_id, permission_id),
    CONSTRAINT fk_role_perm_role FOREIGN KEY (role_id) REFERENCES sys_role(id),
    CONSTRAINT fk_role_perm_perm FOREIGN KEY (permission_id) REFERENCES sys_permission(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE org_school (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    school_name  VARCHAR(100) NOT NULL,
    school_code  VARCHAR(50) UNIQUE,
    province     VARCHAR(50),
    city         VARCHAR(50),
    district     VARCHAR(50),
    address      VARCHAR(300),
    contact_phone VARCHAR(20),
    logo         VARCHAR(500),
    status       INT          NOT NULL DEFAULT 1,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_region (province, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE org_grade (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    grade_name  VARCHAR(50) NOT NULL,
    grade_code  VARCHAR(50),
    grade_level INT,
    school_id   BIGINT      NOT NULL,
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     BIT(1)      NOT NULL DEFAULT 0,
    INDEX idx_school (school_id),
    CONSTRAINT fk_grade_school FOREIGN KEY (school_id) REFERENCES org_school(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE org_class (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    class_name   VARCHAR(50) NOT NULL,
    class_code   VARCHAR(50) UNIQUE,
    grade_id     BIGINT      NOT NULL,
    school_id    BIGINT      NOT NULL,
    teacher_id   BIGINT,
    academic_year VARCHAR(20),
    status       INT         NOT NULL DEFAULT 1,
    created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      BIT(1)      NOT NULL DEFAULT 0,
    INDEX idx_grade (grade_id),
    INDEX idx_school (school_id),
    INDEX idx_teacher (teacher_id),
    CONSTRAINT fk_class_grade FOREIGN KEY (grade_id) REFERENCES org_grade(id),
    CONSTRAINT fk_class_school FOREIGN KEY (school_id) REFERENCES org_school(id),
    CONSTRAINT fk_class_teacher FOREIGN KEY (teacher_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE org_school_member (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    school_id  BIGINT      NOT NULL,
    user_id    BIGINT      NOT NULL,
    role_code  VARCHAR(30) NOT NULL,
    status     INT         NOT NULL DEFAULT 0 COMMENT '0-pending,1-approved,2-rejected',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    BIT(1)      NOT NULL DEFAULT 0,
    UNIQUE KEY uk_school_user (school_id, user_id),
    INDEX idx_school_role (school_id, role_code),
    INDEX idx_user (user_id),
    CONSTRAINT fk_sm_school FOREIGN KEY (school_id) REFERENCES org_school(id),
    CONSTRAINT fk_sm_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE org_class_member (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    class_id   BIGINT      NOT NULL,
    user_id    BIGINT      NOT NULL,
    role_code  VARCHAR(30) NOT NULL,
    join_type  VARCHAR(20) COMMENT 'CODE,SELECT,IMPORT',
    status     INT         NOT NULL DEFAULT 0 COMMENT '0-pending,1-approved,2-rejected',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    BIT(1)      NOT NULL DEFAULT 0,
    UNIQUE KEY uk_class_user (class_id, user_id),
    INDEX idx_class_role (class_id, role_code),
    INDEX idx_user (user_id),
    CONSTRAINT fk_cm_class FOREIGN KEY (class_id) REFERENCES org_class(id),
    CONSTRAINT fk_cm_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sys_sms_code (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone      VARCHAR(20) NOT NULL,
    code       VARCHAR(10) NOT NULL,
    expired    BIT(1)      NOT NULL DEFAULT 0,
    used       BIT(1)      NOT NULL DEFAULT 0,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    BIT(1)      NOT NULL DEFAULT 0,
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mat_tag (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    tag_name    VARCHAR(50) NOT NULL UNIQUE,
    tag_type    VARCHAR(20) NOT NULL DEFAULT 'CUSTOM' COMMENT 'SYSTEM,CUSTOM',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     BIT(1)      NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mat_material (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(1000),
    material_type   VARCHAR(20)  NOT NULL COMMENT 'VIDEO,PDF,IMAGE',
    file_url        VARCHAR(1000) NOT NULL,
    file_size       BIGINT       NOT NULL DEFAULT 0,
    file_name       VARCHAR(300),
    mime_type       VARCHAR(100),
    cover_url       VARCHAR(1000),
    duration        INT COMMENT 'video duration in seconds',
    hls_url         VARCHAR(1000) COMMENT 'HLS transcoded URL for video',
    transcode_status VARCHAR(20) DEFAULT 'NONE' COMMENT 'NONE,PENDING,PROCESSING,DONE,FAILED',
    review_status   VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,APPROVED,REJECTED',
    review_comment  VARCHAR(500),
    reviewer_id     BIGINT,
    scope           VARCHAR(20)  NOT NULL DEFAULT 'SCHOOL' COMMENT 'SCHOOL,CLASS',
    uploader_id     BIGINT       NOT NULL,
    school_id       BIGINT,
    class_id        BIGINT,
    grade_level     INT COMMENT 'applicable grade level',
    view_count      INT          NOT NULL DEFAULT 0,
    download_count  INT          NOT NULL DEFAULT 0,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_type (material_type),
    INDEX idx_uploader (uploader_id),
    INDEX idx_school (school_id),
    INDEX idx_class (class_id),
    INDEX idx_review (review_status),
    INDEX idx_scope (scope),
    CONSTRAINT fk_mat_uploader FOREIGN KEY (uploader_id) REFERENCES sys_user(id),
    CONSTRAINT fk_mat_school FOREIGN KEY (school_id) REFERENCES org_school(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mat_material_tag (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    material_id BIGINT NOT NULL,
    tag_id      BIGINT NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     BIT(1)   NOT NULL DEFAULT 0,
    UNIQUE KEY uk_material_tag (material_id, tag_id),
    INDEX idx_material (material_id),
    INDEX idx_tag (tag_id),
    CONSTRAINT fk_mt_material FOREIGN KEY (material_id) REFERENCES mat_material(id),
    CONSTRAINT fk_mt_tag FOREIGN KEY (tag_id) REFERENCES mat_tag(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mat_review_log (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    material_id     BIGINT       NOT NULL,
    reviewer_id     BIGINT       NOT NULL,
    action          VARCHAR(20)  NOT NULL COMMENT 'APPROVE,REJECT',
    comment         VARCHAR(500),
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_material (material_id),
    CONSTRAINT fk_rl_material FOREIGN KEY (material_id) REFERENCES mat_material(id),
    CONSTRAINT fk_rl_reviewer FOREIGN KEY (reviewer_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO mat_tag (tag_name, tag_type) VALUES
    ('发音示范', 'SYSTEM'),
    ('课文朗读', 'SYSTEM'),
    ('口语技巧', 'SYSTEM'),
    ('语法讲解', 'SYSTEM'),
    ('词汇学习', 'SYSTEM');

CREATE TABLE todo_task (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(1000),
    task_type       VARCHAR(30)  NOT NULL DEFAULT 'GENERAL' COMMENT 'GENERAL,READING,PRACTICE,REVIEW,FOLLOW_READ,READ_ALOUD',
    priority        VARCHAR(10)  NOT NULL DEFAULT 'NORMAL' COMMENT 'LOW,NORMAL,HIGH,URGENT',
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,IN_PROGRESS,COMPLETED,CANCELLED',
    creator_id      BIGINT       NOT NULL,
    assignee_id     BIGINT,
    assignee_type   VARCHAR(20)  DEFAULT 'USER' COMMENT 'USER,CLASS,SCHOOL',
    assignee_class_id BIGINT,
    assignee_school_id BIGINT,
    deadline        DATETIME     NOT NULL,
    completed_at    DATETIME,
    urge_count      INT          NOT NULL DEFAULT 0,
    last_urge_at    DATETIME,
    remind_before_min INT        NOT NULL DEFAULT 30 COMMENT 'remind N minutes before deadline',
    remind_sent     BIT(1)       NOT NULL DEFAULT 0,
    parent_task_id  BIGINT,
    material_id     BIGINT COMMENT 'associated learning material id',
    reference_text  TEXT COMMENT 'reference text for follow-read tasks',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_creator (creator_id),
    INDEX idx_assignee (assignee_id),
    INDEX idx_status (status),
    INDEX idx_deadline (deadline),
    INDEX idx_material (material_id),
    CONSTRAINT fk_todo_creator FOREIGN KEY (creator_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE todo_item (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id              BIGINT       NOT NULL,
    user_id              BIGINT       NOT NULL,
    status               VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING,PENDING_SCORE,COMPLETED,REJECTED,NEEDS_REVIEW',
    feedback             VARCHAR(500),
    score                DOUBLE COMMENT 'scoring result for the checkin',
    audio_url            VARCHAR(500) COMMENT 'audio file URL on OSS',
    duration             INT COMMENT 'audio duration in seconds',
    completed_at         DATETIME,
    teacher_score        DOUBLE COMMENT 'teacher review score',
    teacher_feedback     VARCHAR(1000) COMMENT 'teacher review feedback',
    teacher_audio_url    VARCHAR(500) COMMENT 'teacher review audio URL',
    teacher_id           BIGINT COMMENT 'teacher user id',
    teacher_reviewed_at  DATETIME COMMENT 'teacher review time',
    needs_manual_review  TINYINT(1)   DEFAULT 0 COMMENT 'whether needs manual review',
    retry_count          INT          DEFAULT 0 COMMENT 'scoring retry count',
    created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted              BIT(1)       NOT NULL DEFAULT 0,
    UNIQUE KEY uk_task_user (task_id, user_id),
    INDEX idx_task (task_id),
    INDEX idx_user (user_id),
    INDEX idx_teacher (teacher_id),
    CONSTRAINT fk_ti_task FOREIGN KEY (task_id) REFERENCES todo_task(id),
    CONSTRAINT fk_ti_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS speech_score_detail (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_id              BIGINT       NOT NULL,
    overall_score        DOUBLE,
    pronunciation_score  DOUBLE,
    fluency_score        DOUBLE,
    completeness_score   DOUBLE,
    accuracy_score       DOUBLE,
    error_words_json     TEXT COMMENT 'JSON list of mispronounced words',
    scored_at            DATETIME,
    scoring_provider     VARCHAR(20),
    created_at           DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted              TINYINT(1)   DEFAULT 0,
    INDEX idx_item_id (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE notify_message (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    content         VARCHAR(2000) NOT NULL,
    msg_type        VARCHAR(20)  NOT NULL DEFAULT 'TODO' COMMENT 'TODO,SYSTEM,REMINDER,URGE',
    channel         VARCHAR(20)  NOT NULL DEFAULT 'IN_APP' COMMENT 'IN_APP,EMAIL,DINGTALK,WECHAT',
    sender_id       BIGINT,
    receiver_id     BIGINT       NOT NULL,
    related_id      BIGINT COMMENT 'related task/material id',
    related_type    VARCHAR(20) COMMENT 'TODO,MATERIAL,CLASS',
    is_read         BIT(1)       NOT NULL DEFAULT 0,
    read_at         DATETIME,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_receiver (receiver_id),
    INDEX idx_read (is_read),
    INDEX idx_type (msg_type),
    CONSTRAINT fk_notify_sender FOREIGN KEY (sender_id) REFERENCES sys_user(id),
    CONSTRAINT fk_notify_receiver FOREIGN KEY (receiver_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notify_channel_config (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT       NOT NULL,
    channel         VARCHAR(20)  NOT NULL COMMENT 'IN_APP,EMAIL,DINGTALK,WECHAT',
    channel_value   VARCHAR(300) NOT NULL COMMENT 'email address / dingtalk id / wechat openid',
    enabled         BIT(1)       NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    UNIQUE KEY uk_user_channel (user_id, channel),
    CONSTRAINT fk_ncc_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_device (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT       NOT NULL,
    device_type     VARCHAR(20)  NOT NULL COMMENT 'GETUI,FCP,APNS',
    device_token    VARCHAR(200) NOT NULL COMMENT 'push SDK clientId / device token',
    platform        VARCHAR(20) COMMENT 'android,ios',
    bundle_id       VARCHAR(100),
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    UNIQUE KEY uk_user_device (user_id, device_type),
    INDEX idx_device_type (device_type),
    CONSTRAINT fk_ud_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO sys_role (role_code, role_name, description) VALUES
    ('STUDENT', '学生', '学生角色，可跟读打卡、查看成绩和排行'),
    ('TEACHER', '老师', '老师角色，可下发任务、管理本班学生、查看班级成绩'),
    ('EDU_OFFICE', '教办', '教办角色，可管理全校年级班级、教师、查看全校数据'),
    ('PARENT', '家长', '家长角色，可查看孩子打卡报告和学习数据');

CREATE TABLE IF NOT EXISTS parent_student (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    parent_id       BIGINT       NOT NULL COMMENT '家长用户ID',
    student_id      BIGINT       NOT NULL COMMENT '学生用户ID',
    relation        VARCHAR(20)  COMMENT '关系：父亲、母亲、爷爷、奶奶等',
    is_primary      BIT(1)       NOT NULL DEFAULT 0 COMMENT '是否主要联系人',
    status          INT          NOT NULL DEFAULT 1 COMMENT '0-禁用,1-启用',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    UNIQUE KEY uk_parent_student (parent_id, student_id),
    INDEX idx_student (student_id),
    INDEX idx_parent (parent_id),
    CONSTRAINT fk_ps_parent FOREIGN KEY (parent_id) REFERENCES sys_user(id),
    CONSTRAINT fk_ps_student FOREIGN KEY (student_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS wecom_config (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    school_id       BIGINT       NOT NULL COMMENT '学校ID',
    webhook_url     VARCHAR(500) NOT NULL COMMENT '企业微信机器人Webhook地址',
    secret          VARCHAR(200) COMMENT '签名密钥（可选）',
    config_name     VARCHAR(100) NOT NULL COMMENT '配置名称，如：一年级组、英语教研组等',
    report_type     VARCHAR(50)  NOT NULL DEFAULT 'DAILY' COMMENT 'DAILY-日报,WEEKLY-周报,CUSTOM-自定义',
    enabled         BIT(1)       NOT NULL DEFAULT 1,
    created_by      BIGINT,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         BIT(1)       NOT NULL DEFAULT 0,
    INDEX idx_school (school_id),
    CONSTRAINT fk_wc_school FOREIGN KEY (school_id) REFERENCES org_school(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE notify_message
    ADD COLUMN IF NOT EXISTS send_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING-待发送,SENT-已发送,FAILED-发送失败,RETRYING-重试中',
    ADD COLUMN IF NOT EXISTS retry_count INT NOT NULL DEFAULT 0 COMMENT '重试次数',
    ADD COLUMN IF NOT EXISTS max_retry INT NOT NULL DEFAULT 3 COMMENT '最大重试次数',
    ADD COLUMN IF NOT EXISTS next_retry_at DATETIME COMMENT '下次重试时间',
    ADD COLUMN IF NOT EXISTS last_error TEXT COMMENT '最后一次错误信息',
    ADD COLUMN IF NOT EXISTS sent_at DATETIME COMMENT '实际发送时间',
    ADD COLUMN IF NOT EXISTS extra_data TEXT COMMENT '扩展数据JSON（用于图文卡片等）',
    ADD INDEX IF NOT EXISTS idx_send_status (send_status),
    ADD INDEX IF NOT EXISTS idx_next_retry (next_retry_at);
