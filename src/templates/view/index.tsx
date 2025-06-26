import React from 'react';
import { Link } from 'react-router-dom';

interface {{class_name}} {
{{interface_fields}}
}

interface {{class_name}}IndexProps {
  {{plural_name}}: {{class_name}}[];
}

export default function {{class_name}}Index({ {{plural_name}} }: {{class_name}}IndexProps) {
  return (
    <div className="{{kebab_name}}-index">
      <div className="header">
        <h1>{{title_name}}</h1>
        <Link to="/{{route_path}}/new" className="btn btn-primary">
          New {{singular_title}}
        </Link>
      </div>
      
      <div className="{{kebab_name}}-list">
        {{{plural_name}}.length === 0 ? (
          <div className="empty-state">
            <p>No {{plural_title}} found.</p>
            <Link to="/{{route_path}}/new" className="btn btn-primary">
              Create your first {{singular_title}}
            </Link>
          </div>
        ) : (
          <div className="table-responsive">
            <table className="table">
              <thead>
                <tr>
{{table_headers}}
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {{{plural_name}}.map(({{singular_name}}) => (
                  <tr key={{{singular_name}}.id}>
{{table_cells}}
                    <td>
                      <div className="btn-group">
                        <Link 
                          to={`/{{route_path}}/${{{singular_name}}.id}`}
                          className="btn btn-sm btn-outline-primary"
                        >
                          View
                        </Link>
                        <Link 
                          to={`/{{route_path}}/${{{singular_name}}.id}/edit`}
                          className="btn btn-sm btn-outline-secondary"
                        >
                          Edit
                        </Link>
                        <button 
                          onClick={() => handleDelete({{singular_name}}.id)}
                          className="btn btn-sm btn-outline-danger"
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
        )}
      </div>
    </div>
  );
  
  function handleDelete(id: number) {
    if (confirm('Are you sure you want to delete this {{singular_title}}?')) {
      // TODO: Implement delete functionality
      fetch(`/{{route_path}}/${id}`, {
        method: 'DELETE',
      }).then(() => {
        window.location.reload();
      });
    }
  }
}