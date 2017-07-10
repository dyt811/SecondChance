import React, {Component} from 'react';
import {
  Layout,
  Page,
  FooterHelp,
  Card,
  Link,
  Button,
  FormLayout,
  TextField,
  AccountConnection,
  ChoiceList,
  SettingToggle,
} from '@shopify/polaris';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      first: '',
      last: '',
      email: '',
      checkboxes: [],
      connected: false,
    };
  }

  render() {
    const breadcrumbs = [
      {content: 'Example apps'},
      {content: 'Second Chance'},
    ];
    const primaryAction = {content: 'New Draft Orders'};
    const secondaryActions = [{content: 'Import(Not available yet)', icon: 'import'}];

    const choiceListItems = [
      {label: 'I accept the Terms of Service', value: 'false'},
      {label: 'I consent to receiving emails', value: 'false2'},
    ];

    return (
      <Page
        title="Orders"
        breadcrumbs={breadcrumbs}
        //primaryAction={primaryAction}
        //secondaryActions={secondaryActions}
      >
        <Layout>

          <Layout.AnnotatedSection
            title="Choose Target Order"
            description="Here is where you specify which order to copy."
          >
            <Card sectioned>
              <FormLayout>

                <TextField
                  value={this.state.email}
                  label="Please enter the order number (exactly as it is shown) which you would like to copy to draft order."
                  placeholder="1001"
                  onChange={this.valueUpdater('email')}
                />

                <Button primary>Establish Draft Order Based on Selected Order</Button>
              </FormLayout>
            </Card>
          </Layout.AnnotatedSection>

          <Layout.AnnotatedSection
            title="List of Current Shop Orders"
            description="Here is a list of all the current orders in your store"
          >

          </Layout.AnnotatedSection>

          <Layout.Section>
            <FooterHelp>For more details on SecondChance, visit our <Link url="https://app.shopify.com/second-chance">App Store Page</Link>.</FooterHelp>
          </Layout.Section>

        </Layout>
      </Page>
    );
  }

  valueUpdater(field) {
    return (value) => this.setState({[field]: value});
  }
  toggleConnection() {
    this.setState(({connected}) => ({connected: !connected}));
  }

  connectAccountMarkup() {
    return (
      <Layout.AnnotatedSection
        title="Account"
        description="Connect your account to your Shopify store."
      >
        <AccountConnection
          action={{
            content: 'Connect',
            onAction: this.toggleConnection.bind(this, this.state),
          }}
          details="No account connected"
          termsOfService={<p>By clicking Connect, you are accepting Sample’s <Link url="https://polaris.shopify.com">Terms and Conditions</Link>, including a commission rate of 15% on sales.</p>}
        />
      </Layout.AnnotatedSection>
    );
  }

  disconnectAccountMarkup() {
    return (
      <Layout.AnnotatedSection
          title="Account"
          description="Disconnect your account from your Shopify store."
        >
        <AccountConnection
          connected
          action={{
            content: 'Disconnect',
            onAction: this.toggleConnection.bind(this, this.state),
          }}
          accountName="Tom Ford"
          title={<Link url="http://google.com">Tom Ford</Link>}
          details="Account id: d587647ae4"
        />
      </Layout.AnnotatedSection>
    );
  }

  renderAccount() {
    return this.state.connected
      ? this.disconnectAccountMarkup()
      : this.connectAccountMarkup();
  }
}

export default App;
