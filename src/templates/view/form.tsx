import React, { useState } from 'react';
import { Link } from 'react-router-dom';

interface {{class_name}} {
{{interface_fields}}
}

interface {{class_name}}FormProps {
  {{singular_name}}: Partial<{{class_name}}>;
  errors?: Record<string, string[]>;
  isEdit?: boolean;
}

export default function {{class_name}}Form({ {{singular_name}}, errors = {}, isEdit = false }: {{class_name}}FormProps) {
  const [formData, setFormData] = useState({{singular_name}});
  
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const url = isEdit ? `/{{route_path}}/${{{singular_name}}.id}` : '/{{route_path}}';
    const method = isEdit ? 'PUT' : 'POST';
    
    fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ {{singular_name}}: formData }),
    }).then(response => {
      if (response.ok) {
        window.location.href = isEdit ? `/{{route_path}}/${{{singular_name}}.id}` : '/{{route_path}}';
      } else {
        // Handle validation errors
        response.json().then(data => {
          // Update errors state
        });
      }
    });
  };
  
  const handleChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };
  
  return (
    <div className="{{kebab_name}}-form">
      <div className="header">
        <h1>{isEdit ? 'Edit' : 'New'} {{singular_title}}</h1>
        <Link to="/{{route_path}}" className="btn btn-outline-secondary">
          Cancel
        </Link>
      </div>
      
      <form onSubmit={handleSubmit} className="form">
{{form_fields}}
        
        <div className="form-actions">
          <button type="submit" className="btn btn-primary">
            {isEdit ? 'Update' : 'Create'} {{singular_title}}
          </button>
          <Link to="/{{route_path}}" className="btn btn-outline-secondary">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  );
}