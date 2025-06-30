import { Link, useForm, zodAdapter, router } from "@foguete/orbita";
import { z } from "zod/v4-mini";

const {{class_name}}Schema = z.object({
{{schema_fields}}
});

// Form-specific schema for validation
const {{class_name}}FormSchema = z.object({
{{form_schema_fields}}
});

type {{class_name}} = z.infer<typeof {{class_name}}Schema>;
type {{class_name}}FormData = z.infer<typeof {{class_name}}FormSchema>;

interface {{class_name}}FormProps {
  {{singular_name}}: Partial<{{class_name}}>;
  errors?: Record<string, string[]>;
  isEdit?: boolean;
}

export default function {{class_name}}Form({
  {{singular_name}},
  errors = {},
  isEdit = false,
}: {{class_name}}FormProps) {
  const form = useForm<{{class_name}}FormData>({
    adapter: zodAdapter({{class_name}}FormSchema),
    onSubmit: async (values) => {
      const formData = values;
      const url = isEdit ? `/{{route_path}}/${{{singular_name}}.id}` : "/{{route_path}}";

      // Convert form values to proper types
      const {{singular_name}}Data = {
        {{singular_name}}: {
{{form_data_mapping}}
        },
      };

      try {
        if (isEdit) {
          await router.put(url, {{singular_name}}Data, { preserveUrl: false });
        } else {
          await router.post(url, {{singular_name}}Data, { preserveUrl: false });
        }
      } catch (error) {
        console.error("Form submission error:", error);
        throw error; // Re-throw to let useForm handle the error state
      }
    },
  });
  
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <nav className="flex mb-4" aria-label="Breadcrumb">
            <ol className="flex items-center space-x-4">
              <li>
                <Link href="/{{route_path}}" className="text-gray-400 hover:text-gray-500">
                  {{title_name}}
                </Link>
              </li>
              <li>
                <svg className="flex-shrink-0 h-5 w-5 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd" />
                </svg>
              </li>
              <li>
                <span className="text-gray-500">{isEdit ? 'Edit' : 'New'} {{singular_title}}</span>
              </li>
            </ol>
          </nav>
          
          <h1 className="text-3xl font-bold text-gray-900">
            {isEdit ? 'Edit' : 'Create'} {{singular_title}}
          </h1>
        </div>

        {/* Form */}
        <div className="bg-white shadow sm:rounded-lg">
          <form {...form.formProps}>
            <div className="px-4 py-5 sm:p-6">
              <div className="space-y-6">
{{form_fields}}
              </div>
            </div>

            <div className="px-4 py-3 bg-gray-50 text-right sm:px-6 flex justify-end space-x-3">
              <Link
                href="/{{route_path}}"
                className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Cancel
              </Link>
              <button
                type="submit"
                disabled={form.processing}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
              >
                {form.processing
                  ? isEdit
                    ? "Updating..."
                    : "Creating..."
                  : (isEdit ? "Update" : "Create") + " {{singular_title}}"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}