package com.example.keycloakdemo.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collection;
import java.util.Map;
import java.util.stream.Stream;
import java.util.stream.Collectors;

public class KeycloakJwtAuthenticationConverter implements Converter<Jwt, AbstractAuthenticationToken> {
    private final JwtGrantedAuthoritiesConverter defaultConverter = new JwtGrantedAuthoritiesConverter();

    @Override
    public AbstractAuthenticationToken convert(final Jwt jwt) {
        Collection<GrantedAuthority> authorities = Stream.concat(
            defaultConverter.convert(jwt).stream(),
            extractResourceRoles(jwt).stream()
        ).collect(Collectors.toSet());

        return new JwtAuthenticationToken(jwt, authorities);
    }

    private Collection<? extends GrantedAuthority> extractResourceRoles(final Jwt jwt) {
        Map<String, Object> resourceAccess = jwt.getClaim("resource_access");
        String clientId = jwt.getClaim("azp");
        
        if (resourceAccess == null || clientId == null) {
            return java.util.Collections.emptySet();
        }

        Map<String, Object> resource = (Map<String, Object>) resourceAccess.get(clientId);
        if (resource == null) {
            return java.util.Collections.emptySet();
        }

        Collection<String> roles = (Collection<String>) resource.get("roles");
        if (roles == null) {
            return java.util.Collections.emptySet();
        }

        return roles.stream()
            .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
            .collect(Collectors.toSet());
    }
} 