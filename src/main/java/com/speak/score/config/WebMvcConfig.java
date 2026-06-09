package com.speak.score.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${web-admin.location:#{null}}")
    private String webAdminLocation;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = webAdminLocation;
        if (location == null || location.isEmpty()) {
            File projectRoot = new File(System.getProperty("user.dir"));
            File webAdminDir = new File(projectRoot, "web-admin");
            location = webAdminDir.toURI().toString();
        } else {
            if (!location.startsWith("file:")) {
                location = "file:" + location;
            }
            if (!location.endsWith("/")) {
                location = location + "/";
            }
        }
        registry.addResourceHandler("/web-admin/**")
                .addResourceLocations(location);
    }
}
