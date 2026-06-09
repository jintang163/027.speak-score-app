package com.speak.score.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "mat_material")
public class Material extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "material_type", nullable = false, length = 20)
    private MaterialType materialType;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "file_name", length = 200)
    private String fileName;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "cover_url", length = 500)
    private String coverUrl;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "video_id", length = 100)
    private String videoId;

    @Column(name = "hls_url", length = 500)
    private String hlsUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "transcode_status", nullable = false, length = 20)
    private TranscodeStatus transcodeStatus = TranscodeStatus.NONE;

    @Enumerated(EnumType.STRING)
    @Column(name = "review_status", nullable = false, length = 20)
    private ReviewStatus reviewStatus = ReviewStatus.PENDING;

    @Column(name = "review_comment", length = 500)
    private String reviewComment;

    @Column(name = "reviewer_id")
    private Long reviewerId;

    @Column(name = "scope", nullable = false, length = 20)
    private String scope = "SCHOOL";

    @Column(name = "uploader_id")
    private Long uploaderId;

    @Column(name = "school_id")
    private Long schoolId;

    @Column(name = "class_id")
    private Long classId;

    @Column(name = "grade_level")
    private Integer gradeLevel;

    @Column(name = "view_count", nullable = false)
    private Integer viewCount = 0;

    @Column(name = "download_count", nullable = false)
    private Integer downloadCount = 0;

    @ManyToMany
    @JoinTable(name = "mat_material_tag",
            joinColumns = @JoinColumn(name = "material_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id"))
    private List<MaterialTag> tags = new ArrayList<>();
}
