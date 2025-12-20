import { Card, Col, Row, Typography } from 'antd';
import {
  AppstoreOutlined,
  CodeOutlined,
  DatabaseOutlined,
  ClusterOutlined,
} from '@ant-design/icons';
import type { Application } from '../types/api';

const { Title, Text } = Typography;

const APP_ICONS: Record<string, React.ReactNode> = {
  jenkins: <CodeOutlined style={{ fontSize: 48, color: '#D24939' }} />,
  sonarqube: <DatabaseOutlined style={{ fontSize: 48, color: '#4E9BCD' }} />,
  artifactory: <ClusterOutlined style={{ fontSize: 48, color: '#41BF47' }} />,
  nexus: <AppstoreOutlined style={{ fontSize: 48, color: '#4285F4' }} />,
};

interface AppSelectorProps {
  applications: Application[];
  onSelect: (app: Application) => void;
  loading?: boolean;
}

export default function AppSelector({ applications, onSelect, loading }: AppSelectorProps) {
  return (
    <div>
      <Title level={3}>Select Application</Title>
      <Text type="secondary">Choose the application you want to configure with SAML SSO</Text>

      <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
        {applications.map((app) => (
          <Col xs={24} sm={12} md={6} key={app.id}>
            <Card
              hoverable
              loading={loading}
              onClick={() => onSelect(app)}
              style={{ textAlign: 'center', height: '100%' }}
            >
              <div style={{ marginBottom: 16 }}>
                {APP_ICONS[app.id] || <AppstoreOutlined style={{ fontSize: 48 }} />}
              </div>
              <Title level={4} style={{ marginBottom: 8 }}>
                {app.display_name}
              </Title>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {app.description}
              </Text>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  );
}
