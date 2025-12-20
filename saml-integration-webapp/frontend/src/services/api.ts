import axios from 'axios';
import type { Application, Deployment, DeploymentCreate } from '../types/api';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const applicationsApi = {
  list: async () => {
    const response = await api.get<{ applications: Application[]; total: number }>('/api/v1/applications');
    return response.data;
  },

  get: async (appId: string) => {
    const response = await api.get<Application>(`/api/v1/applications/${appId}`);
    return response.data;
  },
};

export const deploymentsApi = {
  create: async (deployment: DeploymentCreate) => {
    const response = await api.post<Deployment>('/api/v1/deployments', deployment);
    return response.data;
  },

  list: async (params?: { page?: number; page_size?: number; app_type?: string; status?: string }) => {
    const response = await api.get<{ deployments: Deployment[]; total: number; page: number; page_size: number }>(
      '/api/v1/deployments',
      { params }
    );
    return response.data;
  },

  get: async (deploymentId: string) => {
    const response = await api.get<Deployment>(`/api/v1/deployments/${deploymentId}`);
    return response.data;
  },

  cancel: async (deploymentId: string) => {
    await api.delete(`/api/v1/deployments/${deploymentId}`);
  },
};

export const healthApi = {
  check: async () => {
    const response = await api.get('/health');
    return response.data;
  },
};
