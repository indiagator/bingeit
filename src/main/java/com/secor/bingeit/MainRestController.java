package com.secor.bingeit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Random;

@RestController
@RequestMapping("/api/v1")
public class MainRestController {

    @Autowired // another way to ask spring for dependency injection
    UserRepository userRepository;

    @Autowired
    TokenRepository tokenRepository;

    @Autowired
    TokenService tokenService;


    @GetMapping("/welcome")
    public ResponseEntity<?> welcome(@RequestHeader(value = "User-Agent") String userAgent) // Header Value of String Type is being injected into the handler
    {
        return ResponseEntity.ok("Welcome to BingeIt! "+userAgent);
    }

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody Credential credential)
    {
        User user = new User();
        user.setUsername(credential.getUsername());
        user.setPassword(credential.getPassword()); // password should be stored only after encoding and not in plaintext
        userRepository.save(user);

        return ResponseEntity.ok(user);
    }

    @PostMapping("/update/user/details")
    public ResponseEntity<?> updateUserDetails(@RequestBody UserView userView, @RequestHeader("Authorization") String token)
    {
        if(tokenService.validateToken(token))
        {
            if(userRepository.existsById(userView.getUsername()))
            {
                User user = userRepository.findById(userView.getUsername()).get();

                user.setFullname(userView.getFullname());
                user.setEmail(userView.getEmail());
                user.setPhone(userView.getPhone());
                user.setRegion(userView.getRegion());
                userRepository.save(user);
                return ResponseEntity.ok(user);
            }
            else {
                return ResponseEntity.notFound().build();
            }
        }
        else
            {
            return ResponseEntity.status(401).build();
        }



    }

    @GetMapping("login")
    public ResponseEntity<?> login(@RequestBody Credential credential)
    {
        if(userRepository.existsById(credential.getUsername()))
        {
            User user = userRepository.findById(credential.getUsername()).get();
            if(user.getPassword().equals(credential.getPassword()))
            {
                Token token=  tokenService.generateToken(credential.getUsername());
                tokenRepository.save(token);
                return ResponseEntity.ok().header("Authorization",token.getToken()).body("Login Successful");
            }
            else
            {
                return ResponseEntity.badRequest().build();
            }
        }
        else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("validate")
    public ResponseEntity<?> validate(@RequestHeader("Authorization") String token)
    {



        if(tokenService.validateToken(token))
        {
            return ResponseEntity.ok("Token is valid");
        }
        else
        {
            return ResponseEntity.status(401).build();
        }
    }



}
