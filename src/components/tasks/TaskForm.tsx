import React, { useState } from 'react';
import { Save, X, Brain, Plus, ExternalLink, Book, PenTool as Tool, Video, FileText, RotateCw, Check, Edit } from 'lucide-react';
import { generateTasks } from '../../lib/openai';

interface Resource {
  title: string;
  url: string;
  type: string;
  description: string;
}

interface LearningResource {
  title: string;
  url: string;
  type: string;
  platform: string;
  description: string;
}

interface Tool {
  name: string;
  url: string;
  category: string;
  description: string;
}

interface Task {
  id: string;
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high';
  status: 'pending' | 'in_progress' | 'completed';
  category: string;
  task_type: string;
  estimated_hours: number;
  due_date: string;
  implementation_tips?: string[];
  potential_challenges?: string[];
  success_metrics?: string[];
  resources?: Resource[];
  learning_resources?: LearningResource[];
  tools?: Tool[];
}

interface TaskFormProps {
  task?: Task;
  onSubmit: (task: Partial<Task>) => void;
  onCancel: () => void;
}

const defaultTask: Partial<Task> = {
  title: '',
  description: '',
  priority: 'medium',
  status: 'pending',
  category: 'personal',
  task_type: 'Other',
  estimated_hours: 1,
  due_date: new Date().toISOString().split('T')[0],
  implementation_tips: [],
  potential_challenges: [],
  success_metrics: [],
  resources: [],
  learning_resources: [],
  tools: []
};

const TaskForm: React.FC<TaskFormProps> = ({ task, onSubmit, onCancel }) => {
  const [formData, setFormData] = useState<Partial<Task>>({
    ...defaultTask,
    due_date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
    ...(task || {})
  });
  const [isGeneratingAI, setIsGeneratingAI] = useState(false);
  const [isRegenerating, setIsRegenerating] = useState<string | null>(null);

  const generateAISuggestions = async () => {
    if (!formData.title || !formData.description) return;
    setIsGeneratingAI(true);
    
    try {
      const { tasks } = await generateTasks({
        accomplished: '',
        working_on: formData.description,
        blockers: '',
        goals: formData.title
      }, '');

      if (tasks && tasks.length > 0) {
        const suggestions = tasks[0];
        
        setFormData(prev => ({ ...prev, ...suggestions }));
      }
    } catch (error) {
      console.error('Error generating AI suggestions:', error);
    } finally {
      setIsGeneratingAI(false);
    }
  };

  const handleRegenerateSection = async (section: string) => {
    if (!formData.title || !formData.description) return;
    setIsRegenerating(section);
    
    try {
      const { tasks } = await generateTasks({
        accomplished: '',
        working_on: formData.description,
        blockers: '',
        goals: formData.title
      }, '');

      if (tasks && tasks.length > 0) {
        const suggestions = tasks[0];
        setFormData(prev => ({
          ...prev,
          [section]: suggestions[section as keyof typeof suggestions] || []
        }));
      }
    } catch (error) {
      console.error('Error regenerating section:', error);
    } finally {
      setIsRegenerating(null);
    }
  };

  const handleUpdateSuggestion = (section: string, index: number, value: string) => {
    setFormData(prev => ({
      ...prev,
      [section]: (prev[section] as any[])?.map((item, i) => 
        i === index ? (typeof item === 'string' ? value : { ...item, title: value }) : item
      )
    }));
  };

  const handleRemoveSuggestion = (section: string, index: number) => {
    setFormData(prev => ({
      ...prev,
      [section]: (prev[section] as any[])?.filter((_, i) => i !== index)
    }));
  };

  const renderSuggestionItem = (section: string, item: any, index: number) => {
    const itemValue = typeof item === 'string' ? item : item.title;
    return (
      <div className="flex items-center justify-between p-2 rounded bg-white">
        <div className="flex-1">
          <input
            type="text"
            value={itemValue}
            onChange={(e) => handleUpdateSuggestion(section, index, e.target.value)}
            className="w-full text-sm text-gray-600 bg-transparent border-0 focus:ring-0"
          />
        </div>
        <button
          onClick={() => handleRemoveSuggestion(section, index)}
          className="ml-2 text-gray-400 hover:text-gray-500"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const taskData = {
      ...formData,
      status: 'pending',
      // Filter out any empty arrays
      implementation_tips: formData.implementation_tips?.length ? formData.implementation_tips : undefined,
      potential_challenges: formData.potential_challenges?.length ? formData.potential_challenges : undefined,
      success_metrics: formData.success_metrics?.length ? formData.success_metrics : undefined,
      resources: formData.resources?.length ? formData.resources : undefined,
      learning_resources: formData.learning_resources?.length ? formData.learning_resources : undefined,
      tools: formData.tools?.length ? formData.tools : undefined
    };
    onSubmit(taskData);
  };

  const getResourceIcon = (type: string) => {
    switch (type) {
      case 'article':
        return <FileText className="h-4 w-4" />;
      case 'video':
        return <Video className="h-4 w-4" />;
      case 'tool':
        return <Tool className="h-4 w-4" />;
      case 'template':
        return <FileText className="h-4 w-4" />;
      case 'guide':
        return <Book className="h-4 w-4" />;
      default:
        return <ExternalLink className="h-4 w-4" />;
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-4">
        <div>
          <label htmlFor="title" className="block text-sm font-medium text-gray-700">
            Title
          </label>
          <input
            type="text"
            id="title"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            required
          />
        </div>

        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-700">
            Description
          </label>
          <textarea
            id="description"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            rows={3}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="priority" className="block text-sm font-medium text-gray-700">
              Priority
            </label>
            <select
              id="priority"
              value={formData.priority}
              onChange={(e) => setFormData({ ...formData, priority: e.target.value as Task['priority'] })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
            </select>
          </div>

          <div>
            <label htmlFor="task_type" className="block text-sm font-medium text-gray-700">
              Task Type
            </label>
            <select
              id="task_type"
              value={formData.task_type}
              onChange={(e) => setFormData({ ...formData, task_type: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
              <option value="Feature Development">Feature Development</option>
              <option value="Bug Fix">Bug Fix</option>
              <option value="Documentation">Documentation</option>
              <option value="Research">Research</option>
              <option value="Design">Design</option>
              <option value="Planning">Planning</option>
              <option value="Marketing">Marketing</option>
              <option value="Sales">Sales</option>
              <option value="Customer Support">Customer Support</option>
              <option value="Infrastructure">Infrastructure</option>
              <option value="Testing">Testing</option>
              <option value="Analytics">Analytics</option>
              <option value="Process Improvement">Process Improvement</option>
              <option value="Team Coordination">Team Coordination</option>
              <option value="Other">Other</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="estimated_hours" className="block text-sm font-medium text-gray-700">
              Estimated Hours
            </label>
            <input
              type="number"
              id="estimated_hours"
              value={formData.estimated_hours}
              onChange={(e) => setFormData({ ...formData, estimated_hours: parseFloat(e.target.value) })}
              min="0.5"
              step="0.5"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>

          <div>
            <label htmlFor="due_date" className="block text-sm font-medium text-gray-700">
              Due Date
            </label>
            <input
              type="date"
              id="due_date"
              value={formData.due_date}
              onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
            />
          </div>
        </div>

        {/* AI Suggestions Section */}
        <div className="border-t border-gray-200 pt-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-medium text-gray-900">Task Details & AI Suggestions</h3>
            <button
              type="button"
              onClick={generateAISuggestions}
              disabled={isGeneratingAI || !formData.title || !formData.description}
              className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
            >
              {isGeneratingAI ? (
                <>
                  <RotateCw className="h-4 w-4 mr-2 animate-spin" />
                  Generating...
                </>
              ) : (
                <>
                  <Brain className="h-4 w-4 mr-2" />
                  Generate All
                </>
              )}
            </button>
          </div>

          {formData.implementation_tips?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Implementation Tips</h4>
                <button
                  onClick={() => handleRegenerateSection('implementation_tips')}
                  disabled={isRegenerating === 'implementation_tips'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'implementation_tips' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.implementation_tips.map((tip, index) => (
                  <div key={`tip-${index}`} className="text-sm text-gray-600">
                    {renderSuggestionItem('implementation_tips', tip, index)}
                  </div>
                ))}
              </div>
            </div>
          )}

          {formData.potential_challenges?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Potential Challenges</h4>
                <button
                  onClick={() => handleRegenerateSection('potential_challenges')}
                  disabled={isRegenerating === 'potential_challenges'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'potential_challenges' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.potential_challenges.map((challenge, index) => (
                  <div key={`challenge-${index}`} className="text-sm text-gray-600">
                    {renderSuggestionItem('potential_challenges', challenge, index)}
                  </div>
                ))}
              </div>
            </div>
          )}

          {formData.success_metrics?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Success Metrics</h4>
                <button
                  onClick={() => handleRegenerateSection('success_metrics')}
                  disabled={isRegenerating === 'success_metrics'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'success_metrics' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.success_metrics.map((metric, index) => (
                  <div key={`metric-${index}`} className="text-sm text-gray-600">
                    {renderSuggestionItem('success_metrics', metric, index)}
                  </div>
                ))}
              </div>
            </div>
          )}

          {formData.resources?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Resources</h4>
                <button
                  onClick={() => handleRegenerateSection('resources')}
                  disabled={isRegenerating === 'resources'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'resources' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.resources.map((resource, index) => (
                  <div key={`resource-${index}`} className="flex items-center justify-between bg-white p-2 rounded border border-gray-200">
                    {renderSuggestionItem('resources', resource, index)}
                  </div>
                ))}
              </div>
            </div>
          )}

          {formData.learning_resources?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Learning Resources</h4>
                <button
                  onClick={() => handleRegenerateSection('learning_resources')}
                  disabled={isRegenerating === 'learning_resources'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'learning_resources' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.learning_resources.map((resource, index) => (
                  <div key={`learning-${index}`} className="flex items-center justify-between bg-white p-2 rounded border border-gray-200">
                    {renderSuggestionItem('learning_resources', resource, index)}
                  </div>
                ))}
              </div>
            </div>
          )}

          {formData.tools?.length > 0 && (
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-gray-700">Recommended Tools</h4>
                <button
                  onClick={() => handleRegenerateSection('tools')}
                  disabled={isRegenerating === 'tools'}
                  className="text-sm text-indigo-600 hover:text-indigo-900"
                >
                  <RotateCw className={`h-4 w-4 ${isRegenerating === 'tools' ? 'animate-spin' : ''}`} />
                </button>
              </div>
              <div className="space-y-2">
                {formData.tools.map((tool, index) => (
                  <div key={`tool-${index}`} className="flex items-center justify-between bg-white p-2 rounded border border-gray-200">
                    {renderSuggestionItem('tools', tool, index)}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={onCancel}
          className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          <X className="h-4 w-4 mr-2" />
          Cancel
        </button>
        <button
          type="submit"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
        >
          <Save className="h-4 w-4 mr-2" />
          Save Task
        </button>
      </div>
    </form>
  );
};

export default TaskForm;