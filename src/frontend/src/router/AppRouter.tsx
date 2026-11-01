import { Routes, Route, Navigate } from 'react-router-dom';
import { AppLayout } from '../components/layout/AppLayout';
import { MapView } from '../views/MapView';
import { IncidentsView } from '../views/IncidentsView';
import { ObjectsView } from '../views/ObjectsView';
import { ContactsView } from '../views/ContactsView';
import { ShowcaseView } from '../views/ShowcaseView';
import { ScheduleView } from '../views/TeacherView';
import { LoginView } from '../views/LoginView';
import { ProtectedRoute } from './ProtectedRoute';
import { AdministrationView } from '../views/AdministrationView';
import { Role } from '../constants/role';

export const AppRouter = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginView />} />

      <Route element={<AppLayout />}>

        {/* Public general routes */}
        <Route path="/map" element={<MapView />} />
        <Route path="/showcase" element={<ShowcaseView />} />

        {/* Protected general routes */}
        <Route element={<ProtectedRoute unauthorizedTo="/login" />}>
          <Route path="/contacts" element={<ContactsView />} />
          <Route path="/reports" element={<IncidentsView />} />
          <Route path="/objects" element={<ObjectsView />} />
        </Route>

        {/* Role-Restricted Routes */}
        <Route element={<ProtectedRoute allowedRoles={[Role.Admin]} />}>
          <Route path="/administration" element={<AdministrationView />} />
        </Route>

        <Route element={<ProtectedRoute allowedRoles={[Role.Teacher]} />}>
          <Route path="/schedule" element={<ScheduleView />} />
        </Route>

      </Route>

      <Route path="*" element={<Navigate to="/map" />} />
    </Routes>
  );
};
