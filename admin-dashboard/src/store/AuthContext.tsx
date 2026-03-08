import React, { createContext, useContext, useState } from 'react';

type AuthContextType = {
    isAuthenticated: boolean;
    login: (password: string) => boolean;
    logout: () => void;
};

const AuthContext = createContext<AuthContextType>({
    isAuthenticated: false,
    login: () => false,
    logout: () => { },
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [isAuthenticated, setIsAuthenticated] = useState<boolean>(() => {
        return sessionStorage.getItem('admin_token') === 'true';
    });

    const login = (password: string) => {
        if (password === import.meta.env.VITE_ADMIN_PASSWORD) {
            sessionStorage.setItem('admin_token', 'true');
            setIsAuthenticated(true);
            return true;
        }
        return false;
    };

    const logout = () => {
        sessionStorage.removeItem('admin_token');
        setIsAuthenticated(false);
    };

    return (
        <AuthContext.Provider value={{ isAuthenticated, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
