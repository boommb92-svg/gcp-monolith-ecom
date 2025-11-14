package com.example.ecom;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class AppApplication {

    @GetMapping("/")
    public String home() {
        return "<h1>Hello from Ecom App!</h1><p>Deployed via Jenkins + GCP + Docker.</p>";
    }

    public static void main(String[] args) {
        SpringApplication.run(AppApplication.class, args);
    }
}
