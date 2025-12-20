import { useState, useEffect } from 'react';
import { Layout, Typography, message, Spin } from 'antd';
import AppSelector from './components/AppSelector';
import ConfigForm from './components/ConfigForm';
import DeploymentStatus from './components/DeploymentStatus';
import { applicationsApi, deploymentsApi } from './services/api';
import type { Application, Deployment } from './types/api';
import './App.css';

const { Header, Content } = Layout;
const { Title } = Typography;

type Step = 'select' | 'configure' | 'status';

function App() {
  const [step, setStep] = useState<Step>('select');
  const [applications, setApplications] = useState<Application[]>([]);
  const [selectedApp, setSelectedApp] = useState<Application | null>(null);
  const [deployment, setDeployment] = useState<Deployment | null>(null);
  const [loading, setLoading] = useState(false);

  // Load applications on mount
  useEffect(() => {
    loadApplications();
  }, []);

  // Poll deployment status if running
  useEffect(() => {
    if (deployment && deployment.status === 'running') {
      const interval = setInterval(async () => {
        try {
          const updated = await deploymentsApi.get(deployment.id);
          setDeployment(updated);

          if (updated.status !== 'running') {
            clearInterval(interval);
            if (updated.status === 'success') {
              message.success('Deployment completed successfully!');
            } else if (updated.status === 'failed') {
              message.error('Deployment failed. Check the logs for details.');
            }
          }
        } catch (error) {
          console.error('Error polling deployment:', error);
        }
      }, 3000);

      return () => clearInterval(interval);
    }
  }, [deployment]);

  const loadApplications = async () => {
    setLoading(true);
    try {
      const data = await applicationsApi.list();
      setApplications(data.applications);
    } catch (error) {
      message.error('Failed to load applications');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleAppSelect = (app: Application) => {
    setSelectedApp(app);
    setStep('configure');
  };

  const handleConfigSubmit = async (values: Record<string, any>) => {
    if (!selectedApp) return;

    setLoading(true);
    try {
      const newDeployment = await deploymentsApi.create({
        app_type: selectedApp.id,
        configuration: values,
        created_by: 'web-ui',
      });

      setDeployment(newDeployment);
      setStep('status');
      message.success('Deployment started!');
    } catch (error) {
      message.error('Failed to create deployment');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleBack = () => {
    setStep('select');
    setSelectedApp(null);
  };

  const handleNewDeployment = () => {
    setStep('select');
    setSelectedApp(null);
    setDeployment(null);
  };

  const handleViewHistory = () => {
    message.info('Deployment history page coming soon!');
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ background: '#fff', padding: '0 50px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
        <Title level={3} style={{ margin: '14px 0' }}>
          SAML Integration WebApp
        </Title>
      </Header>

      <Content style={{ padding: '50px' }}>
        <div style={{ background: '#fff', padding: 24, minHeight: 500, borderRadius: 8 }}>
          {loading && step === 'select' ? (
            <div style={{ textAlign: 'center', padding: 50 }}>
              <Spin size="large" />
            </div>
          ) : step === 'select' ? (
            <AppSelector applications={applications} onSelect={handleAppSelect} loading={loading} />
          ) : step === 'configure' && selectedApp ? (
            <ConfigForm
              application={selectedApp}
              onSubmit={handleConfigSubmit}
              onBack={handleBack}
              loading={loading}
            />
          ) : step === 'status' && deployment ? (
            <DeploymentStatus
              deployment={deployment}
              onViewHistory={handleViewHistory}
              onNewDeployment={handleNewDeployment}
            />
          ) : null}
        </div>
      </Content>
    </Layout>
  );
}

export default App;
