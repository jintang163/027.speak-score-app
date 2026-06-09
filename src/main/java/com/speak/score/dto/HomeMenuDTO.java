package com.speak.score.dto;

import com.speak.score.entity.RoleEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HomeMenuDTO {

    private RoleEnum role;
    private List<MenuItem> menus;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MenuItem {
        private String key;
        private String title;
        private String icon;
        private String route;
    }
}
