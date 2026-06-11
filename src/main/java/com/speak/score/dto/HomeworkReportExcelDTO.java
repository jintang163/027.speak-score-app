package com.speak.score.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

@Data
public class HomeworkReportExcelDTO {

    @ExcelProperty(value = "学生姓名", index = 0)
    private String studentName;

    @ExcelProperty(value = "学号", index = 1)
    private String studentNo;

    @ExcelProperty(value = "班级", index = 2)
    private String className;

    @ExcelProperty(value = "总任务数", index = 3)
    private Integer totalTasks;

    @ExcelProperty(value = "已完成", index = 4)
    private Integer completedTasks;

    @ExcelProperty(value = "未完成", index = 5)
    private Integer pendingTasks;

    @ExcelProperty(value = "完成率", index = 6)
    private String completionRate;

    @ExcelProperty(value = "平均分", index = 7)
    private String averageScore;

    @ExcelProperty(value = "最高分", index = 8)
    private String highestScore;

    @ExcelProperty(value = "最低分", index = 9)
    private String lowestScore;

    @ExcelProperty(value = "统计周期", index = 10)
    private String period;
}
