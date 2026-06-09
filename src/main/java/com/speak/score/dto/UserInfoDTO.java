package com.speak.score.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoDTO {

    private Long id;
    private String username;
    private String nickname;
    private String realName;
    private String avatar;
    private String phone;
    private Integer gender;
    private List<String> roles;
    private Long schoolId;
    private String schoolName;
    private Long classId;
    private String className;
    private Long gradeId;
    private String gradeName;
}
