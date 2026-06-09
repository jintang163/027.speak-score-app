package com.speak.score.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

@Data
public class StudentExcelDTO {

    @ExcelProperty(value = "姓名", index = 0)
    private String realName;

    @ExcelProperty(value = "手机号", index = 1)
    private String phone;

    @ExcelProperty(value = "性别", index = 2)
    private String genderStr;

    @ExcelProperty(value = "学号", index = 3)
    private String studentNo;
}
