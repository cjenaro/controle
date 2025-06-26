import { Link } from "@foguete/orbita";

interface {{class_name}} {
{{interface_fields}}
}

interface {{class_name}}IndexProps {
  {{plural_name}}: {{class_name}}[];
}

export default function {{class_name}}Index({ {{plural_name}} }: {{class_name}}IndexProps) {
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="sm:flex sm:items-center sm:justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">{{title_name}}</h1>
            <p className="mt-2 text-sm text-gray-700">
              Manage your {{plural_title}} here
            </p>
          </div>
          <div className="mt-4 sm:mt-0">
            <Link
              href="/{{route_path}}/new"
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <svg className="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              New {{singular_title}}
            </Link>
          </div>
        </div>

        {/* Content */}
        {{{plural_name}}.length === 0 ? (
          <div className="text-center py-12">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No {{plural_title}}</h3>
            <p className="mt-1 text-sm text-gray-500">Get started by creating your first {{singular_title}}.</p>
            <div className="mt-6">
              <Link
                href="/{{route_path}}/new"
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg className="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                New {{singular_title}}
              </Link>
            </div>
          </div>
        ) : (
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
{{table_headers}}
                    <th scope="col" className="relative px-6 py-3">
                      <span className="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {{{plural_name}}.map(({{singular_name}}) => (
                    <tr key={{{singular_name}}.id} className="hover:bg-gray-50">
{{table_cells}}
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex items-center space-x-2">
                          <Link
                            href={`/{{route_path}}/${{{singular_name}}.id}`}
                            className="text-indigo-600 hover:text-indigo-900 font-medium"
                          >
                            View
                          </Link>
                          <Link
                            href={`/{{route_path}}/${{{singular_name}}.id}/edit`}
                            className="text-gray-600 hover:text-gray-900 font-medium"
                          >
                            Edit
                          </Link>
                          <button
                            onClick={() => handleDelete({{singular_name}}.id)}
                            className="text-red-600 hover:text-red-900 font-medium"
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );

  function handleDelete(id: number) {
    if (confirm('Are you sure you want to delete this {{singular_title}}?')) {
      fetch(`/{{route_path}}/${id}`, {
        method: 'DELETE',
      }).then(() => {
        window.location.reload();
      });
    }
  }
}