import { Card, Typography, Tag, Spin, Alert, Button, Descriptions } from 'antd';
import { CheckCircleOutlined, CloseCircleOutlined, LoadingOutlined, ClockCircleOutlined } from '@ant-design/icons';
import type { Deployment, DeploymentStatus as StatusType } from '../types/api';

const { Title, Text, Paragraph } = Typography;

interface DeploymentStatusProps {
  deployment: Deployment;
  onViewHistory: () => void;
  onNewDeployment: () => void;
}

const STATUS_CONFIG: Record<StatusType, { color: string; icon: React.ReactNode; text: string }> = {
  pending: {
    color: 'default',
    icon: <ClockCircleOutlined />,
    text: 'Pending',
  },
  running: {
    color: 'processing',
    icon: <LoadingOutlined />,
    text: 'Running',
  },
  success: {
    color: 'success',
    icon: <CheckCircleOutlined />,
    text: 'Success',
  },
  failed: {
    color: 'error',
    icon: <CloseCircleOutlined />,
    text: 'Failed',
  },
  cancelled: {
    color: 'warning',
    icon: <CloseCircleOutlined />,
    text: 'Cancelled',
  },
};

export default function DeploymentStatus({ deployment, onViewHistory, onNewDeployment }: DeploymentStatusProps) {
  const statusConfig = STATUS_CONFIG[deployment.status];

  return (
    <Card>
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontSize: 64, marginBottom: 16 }}>{statusConfig.icon}</div>
        <Title level={2}>Deployment {statusConfig.text}</Title>
        <Tag color={statusConfig.color} style={{ fontSize: 16, padding: '4px 12px' }}>
          {statusConfig.text.toUpperCase()}
        </Tag>
      </div>

      {deployment.status === 'running' && (
        <Alert
          message="Deployment in Progress"
          description="The Ansible playbook is being executed. This may take a few minutes..."
          type="info"
          showIcon
          icon={<Spin />}
          style={{ marginBottom: 24 }}
        />
      )}

      {deployment.status === 'success' && (
        <Alert
          message="Deployment Successful!"
          description="SAML SSO integration has been configured successfully."
          type="success"
          showIcon
          style={{ marginBottom: 24 }}
        />
      )}

      {deployment.status === 'failed' && deployment.error_message && (
        <Alert
          message="Deployment Failed"
          description={deployment.error_message}
          type="error"
          showIcon
          style={{ marginBottom: 24 }}
        />
      )}

      <Descriptions bordered column={1} size="small">
        <Descriptions.Item label="Deployment ID">{deployment.id}</Descriptions.Item>
        <Descriptions.Item label="Application">{deployment.app_type.toUpperCase()}</Descriptions.Item>
        <Descriptions.Item label="Status">
          <Tag color={statusConfig.color}>{deployment.status}</Tag>
        </Descriptions.Item>
        <Descriptions.Item label="Created">
          {new Date(deployment.created_at).toLocaleString()}
        </Descriptions.Item>
        {deployment.completed_at && (
          <Descriptions.Item label="Completed">
            {new Date(deployment.completed_at).toLocaleString()}
          </Descriptions.Item>
        )}
        {deployment.duration_seconds && (
          <Descriptions.Item label="Duration">{deployment.duration_seconds.toFixed(1)}s</Descriptions.Item>
        )}
      </Descriptions>

      {deployment.playbook_output && (
        <div style={{ marginTop: 24 }}>
          <Title level={4}>Ansible Output</Title>
          <pre
            style={{
              background: '#f5f5f5',
              padding: 16,
              borderRadius: 4,
              maxHeight: 400,
              overflow: 'auto',
              fontSize: 12,
            }}
          >
            {deployment.playbook_output}
          </pre>
        </div>
      )}

      <div style={{ marginTop: 24, textAlign: 'center' }}>
        <Button onClick={onViewHistory} style={{ marginRight: 8 }}>
          View All Deployments
        </Button>
        <Button type="primary" onClick={onNewDeployment}>
          New Deployment
        </Button>
      </div>
    </Card>
  );
}
