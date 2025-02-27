package com.secor.bingeit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class TokenService {

    @Autowired
    TokenRepository tokenRepository;

    public Token generateToken(String username)
    {
        Token token = new Token();
        token.setUsername(username);
        token.setStatus("valid");
        token.setToken(String.valueOf(new Random().nextInt(1000000)));

        return token;
    }

    public boolean validateToken(String token)
    {
        String[] tokenArray = token.split(" ");
        String tokenS = tokenArray[1];

        if(tokenRepository.findById(tokenS).isPresent())
        {
            Token tokenObj = tokenRepository.findById(tokenS).get();
            if(tokenObj.getStatus().equals("valid"))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            return false;
        }

    }

    public void invalidateToken(String token)
    {
        String[] tokenArray = token.split(" ");
        String tokenS = tokenArray[1];

        if(tokenRepository.findById(tokenS).isPresent())
        {
            Token tokenObj = tokenRepository.findById(tokenS).get();
            tokenObj.setStatus("invalid");
            tokenRepository.save(tokenObj);
        }
    }




}
