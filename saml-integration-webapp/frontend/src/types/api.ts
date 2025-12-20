export interface Application {
  id: string;
  name: string;
  display_name: string;
  description: string;
  icon_url?: string;
  is_active: boolean;
  config_fields: ConfigField[];
  default_config: Record<string, any>;
}

export interface ConfigField {
  name: string;
  label: string;
  type: 'text' | 'url' | 'select' | 'checkbox' | 'password';
  required: boolean;
  default?: any;
  help_text?: string;
  options?: string[];
}

export type DeploymentStatus = 'pending' | 'running' | 'success' | 'failed' | 'cancelled';

export interface Deployment {
  id: string;
  app_type: string;
  status: DeploymentStatus;
  configuration: Record<string, any>;
  playbook_output?: string;
  error_message?: string;
  ansible_stats?: Record<string, any>;
  created_at: string;
  started_at?: string;
  completed_at?: string;
  created_by?: string;
  duration_seconds?: number;
}

export interface DeploymentCreate {
  app_type: string;
  configuration: Record<string, any>;
  created_by?: string;
}
