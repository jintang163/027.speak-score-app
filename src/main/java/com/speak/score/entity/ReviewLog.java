package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "mat_review_log")
public class ReviewLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "material_id", nullable = false)
    private Long materialId;

    @Column(name = "reviewer_id", nullable = false)
    private Long reviewerId;

    @Column(name = "action", nullable = false, length = 20)
    private String action;

    @Column(name = "comment", length = 500)
    private String comment;
}
