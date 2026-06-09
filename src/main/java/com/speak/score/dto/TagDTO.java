package com.speak.score.dto;

import com.speak.score.entity.MaterialTag;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TagDTO {

    private Long id;
    private String tagName;
    private String tagType;

    public static TagDTO fromEntity(MaterialTag t) {
        if (t == null) {
            return null;
        }
        TagDTO dto = new TagDTO();
        dto.setId(t.getId());
        dto.setTagName(t.getTagName());
        dto.setTagType(t.getTagType());
        return dto;
    }
}
