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

INSERT INTO sys_role (role_code, role_name, description) VALUES
    ('STUDENT', '学生', '学生角色，可跟读打卡、查看成绩和排行'),
    ('TEACHER', '老师', '老师角色，可下发任务、管理本班学生、查看班级成绩'),
    ('EDU_OFFICE', '教办', '教办角色，可管理全校年级班级、教师、查看全校数据');
