package com.speak.score.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolDTO {

    private Long id;
    private String schoolName;
    private String schoolCode;
    private String province;
    private String city;
    private String district;
    private String address;
    private String contactPhone;
    private String logo;
    private Integer status;
}
