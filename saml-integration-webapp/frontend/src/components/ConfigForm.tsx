import { Form, Input, Button, Typography, Alert } from 'antd';
import type { Application } from '../types/api';

const { Title, Text } = Typography;

interface ConfigFormProps {
  application: Application;
  onSubmit: (values: Record<string, any>) => void;
  onBack: () => void;
  loading?: boolean;
}

export default function ConfigForm({ application, onSubmit, onBack, loading }: ConfigFormProps) {
  const [form] = Form.useForm();

  // Set initial values from defaults
  const initialValues: Record<string, any> = {};
  application.config_fields.forEach((field) => {
    if (field.default !== undefined) {
      initialValues[field.name] = field.default;
    }
  });

  return (
    <div>
      <Button onClick={onBack} style={{ marginBottom: 16 }}>
        ← Back to Applications
      </Button>

      <Title level={3}>Configure {application.display_name} SAML Integration</Title>
      <Text type="secondary">{application.description}</Text>

      <Alert
        message="SAML Configuration"
        description="Fill in the configuration details below. This will execute an Ansible playbook to configure SAML SSO integration."
        type="info"
        showIcon
        style={{ margin: '24px 0' }}
      />

      <Form
        form={form}
        layout="vertical"
        initialValues={initialValues}
        onFinish={onSubmit}
        style={{ maxWidth: 600 }}
      >
        {application.config_fields.map((field) => (
          <Form.Item
            key={field.name}
            label={field.label}
            name={field.name}
            rules={[
              {
                required: field.required,
                message: `Please input ${field.label}`,
              },
              field.type === 'url'
                ? {
                    type: 'url',
                    message: 'Please enter a valid URL',
                  }
                : {},
            ]}
            help={field.help_text}
          >
            {field.type === 'password' ? (
              <Input.Password placeholder={field.label} />
            ) : field.type === 'checkbox' ? (
              <Input type="checkbox" />
            ) : (
              <Input placeholder={field.label} />
            )}
          </Form.Item>
        ))}

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} size="large">
            Deploy SAML Integration
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
