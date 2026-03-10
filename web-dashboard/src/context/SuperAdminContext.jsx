import { createContext, useContext, useState, useEffect } from 'react';

const SuperAdminContext = createContext();

const SUPER_ADMIN_USERNAME = 'Kyotaka';
const SUPER_ADMIN_PASSWORD = 'Kyotaka123';
const STORAGE_KEY = 'wiwc_superadmin_auth';

export function useSuperAdmin() {
  return useContext(SuperAdminContext);
}

export function SuperAdminProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const data = JSON.parse(stored);
        // Session expires after 24 hours
        if (data.timestamp && Date.now() - data.timestamp < 24 * 60 * 60 * 1000) {
          return true;
        }
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch { }
    return false;
  });

  function login(username, password) {
    if (username === SUPER_ADMIN_USERNAME && password === SUPER_ADMIN_PASSWORD) {
      setIsAuthenticated(true);
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        authenticated: true,
        timestamp: Date.now(),
        username: SUPER_ADMIN_USERNAME,
      }));
      return true;
    }
    return false;
  }

  function logout() {
    setIsAuthenticated(false);
    localStorage.removeItem(STORAGE_KEY);
  }

  const value = {
    isAuthenticated,
    login,
    logout,
    username: SUPER_ADMIN_USERNAME,
  };

  return (
    <SuperAdminContext.Provider value={value}>
      {children}
    </SuperAdminContext.Provider>
  );
}
