package com.speak.score.entity;

import javax.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "org_school_member")
public class SchoolMember extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id", nullable = false)
    private School school;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "role_code", nullable = false, length = 30)
    private RoleEnum roleCode;

    @Column(name = "status", nullable = false)
    private Integer status = 0;

    public enum JoinStatus {
        PENDING(0),
        APPROVED(1),
        REJECTED(2);

        private final int code;

        JoinStatus(int code) {
            this.code = code;
        }

        public int getCode() {
            return code;
        }
    }
}
