import { useOrbita } from "@foguete/orbita";
import { useState } from "preact/hooks";

export default function Home(props: any) {
  const { post } = useOrbita();
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  const handleGreeting = async () => {
    setLoading(true);
    setMessage("");
    
    try {
      await post("/greet", {
        data: { name: "Foguete User" },
        onSuccess: (page) => {
          setMessage(page.props.flash?.success || "Hello from the server!");
        },
        onError: (errors) => {
          setMessage("Something went wrong!");
        }
      });
    } catch (error) {
      setMessage("Network error occurred!");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            Welcome to <span className="text-indigo-600">{{app_name}}</span>!
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Your Foguete application is ready to go. Start building amazing web applications with Lua and Preact.
          </p>
        </div>

        {/* Interactive Demo */}
        <div className="max-w-md mx-auto mb-12">
          <div className="bg-white rounded-lg shadow-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Try Server Interaction
            </h3>
            <p className="text-gray-600 mb-4">
              Click the button below to send a request to your Lua server!
            </p>
            
            <button
              onClick={handleGreeting}
              disabled={loading}
              className={`w-full py-3 px-4 rounded-lg font-medium transition-all duration-200 ${
                loading
                  ? "bg-gray-400 cursor-not-allowed"
                  : "bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800"
              } text-white shadow-md hover:shadow-lg`}
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Sending...
                </span>
              ) : (
                "Say Hello to Server"
              )}
            </button>
            
            {message && (
              <div className={`mt-4 p-3 rounded-lg ${
                message.includes("error") || message.includes("wrong")
                  ? "bg-red-50 text-red-700 border border-red-200"
                  : "bg-green-50 text-green-700 border border-green-200"
              }`}>
                {message}
              </div>
            )}
          </div>
        </div>

        {/* Next Steps */}
        <div className="max-w-4xl mx-auto mb-12">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Next Steps</h2>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-indigo-100 rounded-full flex items-center justify-center">
                    <span className="text-indigo-600 text-sm font-medium">1</span>
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Generate a Model</h3>
                    <code className="text-sm text-gray-600 bg-gray-100 px-2 py-1 rounded">
                      fog generate model User name:string email:string
                    </code>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-indigo-100 rounded-full flex items-center justify-center">
                    <span className="text-indigo-600 text-sm font-medium">2</span>
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Generate a Controller</h3>
                    <code className="text-sm text-gray-600 bg-gray-100 px-2 py-1 rounded">
                      fog generate controller Users
                    </code>
                  </div>
                </div>
              </div>
              
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-indigo-100 rounded-full flex items-center justify-center">
                    <span className="text-indigo-600 text-sm font-medium">3</span>
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Generate a Scaffold</h3>
                    <code className="text-sm text-gray-600 bg-gray-100 px-2 py-1 rounded">
                      fog generate scaffold Post title:string content:text
                    </code>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <div className="flex-shrink-0 w-6 h-6 bg-indigo-100 rounded-full flex items-center justify-center">
                    <span className="text-indigo-600 text-sm font-medium">4</span>
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Run Migrations</h3>
                    <code className="text-sm text-gray-600 bg-gray-100 px-2 py-1 rounded">
                      fog db:migrate
                    </code>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Debug Info */}
        <div className="max-w-4xl mx-auto">
          <div className="bg-gray-50 rounded-lg p-6 border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Debug Information</h3>
            <div className="bg-white rounded border p-4">
              <h4 className="font-medium text-gray-700 mb-2">Props received from server:</h4>
              <pre className="text-sm text-gray-600 overflow-x-auto">
                {JSON.stringify(props, null, 2)}
              </pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}