import { Navigate, Outlet } from "react-router-dom";
import type { Role } from "../constants/role";
import { useAuthState } from "../states/authState";

interface ProtectedRouteProps {
  allowedRoles?: Role[];
  unauthorizedTo?: string;
}

export const ProtectedRoute = ({
  allowedRoles,
  unauthorizedTo = "/map"
}: ProtectedRouteProps) => {
  const { isAuthenticated, user } = useAuthState();

  // Avoid unauthorized users requests
  if (!isAuthenticated || !user) {
    return <Navigate to={unauthorizedTo} replace />;
  }

  if (allowedRoles && allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
    return <Navigate to={unauthorizedTo} replace />;
  }

  // Authorized user
  return <Outlet/>;
}
