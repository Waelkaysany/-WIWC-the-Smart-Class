import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { SuperAdminProvider, useSuperAdmin } from './context/SuperAdminContext';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import ApproveUser from './pages/ApproveUser';
import SuperAdminLogin from './pages/SuperAdminLogin';
import SuperAdminDashboard from './pages/SuperAdminDashboard';
import TeachersList from './pages/TeachersList';
import SupportRequests from './pages/SupportRequests';

function PrivateRoute({ children }) {
  const { currentUser } = useAuth();
  return currentUser ? children : <Navigate to="/login" />;
}

function SuperAdminRoute({ children }) {
  const { isAuthenticated } = useSuperAdmin();
  return isAuthenticated ? children : <Navigate to="/superadmin/login" />;
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <SuperAdminProvider>
          <Routes>
            {/* Teacher / Admin routes */}
            <Route path="/login" element={<Login />} />
            <Route path="/approve" element={<ApproveUser />} />
            <Route
              path="/"
              element={
                <PrivateRoute>
                  <Dashboard />
                </PrivateRoute>
              }
            />

            {/* SuperAdmin routes */}
            <Route path="/superadmin/login" element={<SuperAdminLogin />} />
            <Route
              path="/superadmin"
              element={
                <SuperAdminRoute>
                  <SuperAdminDashboard />
                </SuperAdminRoute>
              }
            />
            <Route
              path="/superadmin/teachers"
              element={
                <SuperAdminRoute>
                  <TeachersList />
                </SuperAdminRoute>
              }
            />
            <Route
              path="/superadmin/support"
              element={
                <SuperAdminRoute>
                  <SupportRequests />
                </SuperAdminRoute>
              }
            />
          </Routes>
        </SuperAdminProvider>
      </AuthProvider>
    </Router>
  );
}

export default App;
