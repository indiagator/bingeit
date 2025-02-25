package com.secor.bingeit;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "tokens")
@Getter @Setter
public class Token {

    @Id
    private String token;
    private String username;
    private String status;
}
