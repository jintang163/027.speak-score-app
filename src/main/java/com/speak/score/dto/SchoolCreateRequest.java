package com.speak.score.dto;

import javax.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SchoolCreateRequest {

    @NotBlank(message = "schoolName is required")
    private String schoolName;

    private String schoolCode;
    private String province;
    private String city;
    private String district;
    private String address;
    private String contactPhone;
    private String logo;
}
