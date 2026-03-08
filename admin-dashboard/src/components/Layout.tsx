import React from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { useAuth } from '../store/AuthContext';

export const Layout = () => {
    const { isAuthenticated } = useAuth();

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    return (
        <div className="flex h-screen bg-background text-gray-100 overflow-hidden" dir="rtl">
            <Sidebar />
            <main className="flex-1 overflow-auto p-8">
                <Outlet />
            </main>
        </div>
    );
};
