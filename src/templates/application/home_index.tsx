export default function Home(props: any) {
  return (
    <div>
      <h1>Welcome to {{app_name}}!</h1>
      <p>Your Foguete application is ready to go.</p>
      
      <div style={{ marginTop: "2rem" }}>
        <h2>Next Steps:</h2>
        <ul>
          <li>Generate a model: <code>fog generate model User name:string email:string</code></li>
          <li>Generate a controller: <code>fog generate controller Users</code></li>
          <li>Generate a complete scaffold: <code>fog generate scaffold Post title:string content:text</code></li>
          <li>Run migrations: <code>fog db:migrate</code></li>
        </ul>
      </div>

      <div style={{ marginTop: "2rem", padding: "1rem", backgroundColor: "#f5f5f5", borderRadius: "4px" }}>
        <h3>Props received:</h3>
        <pre>{JSON.stringify(props, null, 2)}</pre>
      </div>
    </div>
  );
}