package com.speak.score.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VodUploadAuthDTO {
    private String videoId;
    private String uploadAuth;
    private String uploadAddress;
    private String requestId;
}
