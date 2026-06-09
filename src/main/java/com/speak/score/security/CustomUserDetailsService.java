package com.speak.score.security;

import com.speak.score.entity.RoleEnum;
import com.speak.score.entity.User;
import com.speak.score.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String phone) throws UsernameNotFoundException {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with phone: " + phone));

        return buildUserDetails(user);
    }

    public UserDetails loadUserByWechatOpenid(String openid) throws UsernameNotFoundException {
        User user = userRepository.findByWechatOpenid(openid)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with wechat openid: " + openid));

        return buildUserDetails(user);
    }

    public UserDetails loadUserById(Long id) throws UsernameNotFoundException {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + id));

        return buildUserDetails(user);
    }

    private UserDetails buildUserDetails(User user) {
        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getRoleCode().name()))
                .collect(Collectors.toList());

        boolean isStudent = user.getRoles().stream()
                .anyMatch(role -> role.getRoleCode() == RoleEnum.STUDENT);

        return new org.springframework.security.core.userdetails.User(
                String.valueOf(user.getId()),
                user.getPassword() != null ? user.getPassword() : "",
                user.getEnabled(),
                user.getAccountNonLocked(),
                true,
                true,
                authorities
        );
    }
}
