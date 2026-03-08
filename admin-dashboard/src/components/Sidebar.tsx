import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, Clock, Settings, LogOut } from 'lucide-react';
import { useAuth } from '../store/AuthContext';
import clsx from 'clsx';

export const Sidebar = () => {
    const { logout } = useAuth();

    const navItems = [
        { to: '/', icon: LayoutDashboard, label: 'الرئيسية' },
        { to: '/pending', icon: Clock, label: 'الطلبات المعلقة' },
        { to: '/users', icon: Users, label: 'المستخدمين' },
        { to: '/settings', icon: Settings, label: 'الإعدادات' },
    ];

    return (
        <div className="w-64 bg-surface h-screen border-l border-gray-800 flex flex-col">
            <div className="p-6 border-b border-gray-800">
                <h1 className="text-2xl font-bold text-primary">مدير الديون</h1>
                <p className="text-xs text-gray-400 mt-1">لوحة تحكم الإدارة</p>
            </div>

            <nav className="flex-1 p-4 space-y-2">
                {navItems.map((item) => (
                    <NavLink
                        key={item.to}
                        to={item.to}
                        className={({ isActive }) =>
                            clsx(
                                'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors',
                                isActive
                                    ? 'bg-primary/10 text-primary'
                                    : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                            )
                        }
                    >
                        <item.icon size={20} />
                        <span className="font-medium">{item.label}</span>
                    </NavLink>
                ))}
            </nav>

            <div className="p-4 border-t border-gray-800">
                <button
                    onClick={logout}
                    className="flex items-center gap-3 px-4 py-3 w-full text-danger hover:bg-danger/10 rounded-lg transition-colors"
                >
                    <LogOut size={20} />
                    <span className="font-medium">تسجيل الخروج</span>
                </button>
            </div>
        </div>
    );
};
