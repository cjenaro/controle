import React from 'react';
import { Link } from 'react-router-dom';

interface {{class_name}} {
{{interface_fields}}
}

interface {{class_name}}ShowProps {
  {{singular_name}}: {{class_name}};
}

export default function {{class_name}}Show({ {{singular_name}} }: {{class_name}}ShowProps) {
  return (
    <div className="{{kebab_name}}-show">
      <div className="header">
        <h1>{{singular_title}}</h1>
        <div className="btn-group">
          <Link to="/{{route_path}}" className="btn btn-outline-secondary">
            Back to {{title_name}}
          </Link>
          <Link 
            to={`/{{route_path}}/${{{singular_name}}.id}/edit`}
            className="btn btn-primary"
          >
            Edit
          </Link>
          <button 
            onClick={handleDelete}
            className="btn btn-outline-danger"
          >
            Delete
          </button>
        </div>
      </div>
      
      <div className="{{kebab_name}}-details">
{{detail_fields}}
      </div>
    </div>
  );
  
  function handleDelete() {
    if (confirm('Are you sure you want to delete this {{singular_title}}?')) {
      fetch(`/{{route_path}}/${{{singular_name}}.id}`, {
        method: 'DELETE',
      }).then(() => {
        window.location.href = '/{{route_path}}';
      });
    }
  }
}