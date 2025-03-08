import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { 
  Rocket, 
  ArrowLeft, 
  Save, 
  Plus, 
  Presentation, 
  ChevronLeft, 
  ChevronRight, 
  Share2,
  Download,
  Copy,
  Check,
  Globe,
  Lock,
  Sparkles,
  Loader2
} from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../lib/store';
import { createGoogleSlides } from '../../lib/slides';
import { generatePitchDeck } from '../../lib/openai';
import * as Dialog from '@radix-ui/react-dialog';

interface Slide {
  id: string;
  type: 'cover' | 'problem' | 'solution' | 'market' | 'business' | 'team' | 'custom';
  title: string;
  content: {
    text?: string;
    bullets?: string[];
    image?: string;
  };
}

interface BusinessInfo {
  companyName: string;
  tagline: string;
  problem: string;
  solution: string;
  market: string;
  businessModel: string;
  competition: string;
  teamInfo: string;
  financials: string;
  askAmount?: string;
}

export default function PitchDeck() {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const [title, setTitle] = useState('Pitch Deck');
  const [deckId, setDeckId] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isPublic, setIsPublic] = useState(false);
  const [shareUrl, setShareUrl] = useState('');
  const [showShareDialog, setShowShareDialog] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [showGenerateDialog, setShowGenerateDialog] = useState(false);
  const [businessInfo, setBusinessInfo] = useState<BusinessInfo>({
    companyName: '',
    tagline: '',
    problem: '',
    solution: '',
    market: '',
    businessModel: '',
    competition: '',
    teamInfo: '',
    financials: '',
    askAmount: ''
  });
  const [slides, setSlides] = useState<Slide[]>([
    {
      id: '1',
      type: 'cover',
      title: 'Company Name',
      content: {
        text: 'Tagline goes here'
      }
    },
    {
      id: '2',
      type: 'problem',
      title: 'The Problem',
      content: {
        text: 'Describe the problem you\'re solving',
        bullets: [
          'Pain point 1',
          'Pain point 2',
          'Pain point 3'
        ]
      }
    },
    {
      id: '3',
      type: 'solution',
      title: 'Our Solution',
      content: {
        text: 'Describe your solution',
        image: 'https://via.placeholder.com/800x400'
      }
    }
  ]);

  useEffect(() => {
    if (user) {
      loadDeck();
    }
  }, [user]);

  const loadDeck = async () => {
    try {
      const { data: deck, error } = await supabase
        .from('pitch_decks')
        .select('*')
        .eq('user_id', user?.id)
        .order('updated_at', { ascending: false })
        .limit(1)
        .single();

      if (error) throw error;

      if (deck) {
        setDeckId(deck.id);
        setTitle(deck.title);
        setSlides(deck.slides);
        setIsPublic(deck.is_public);
        setShareUrl(`${window.location.origin}/pitch-deck/${deck.id}`);
      }
    } catch (error) {
      console.error('Error loading deck:', error);
    }
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);

      const deckData = {
        title,
        slides,
        is_public: isPublic,
        user_id: user?.id
      };

      if (deckId) {
        // Update existing deck
        const { error } = await supabase
          .from('pitch_decks')
          .update(deckData)
          .eq('id', deckId);

        if (error) throw error;
      } else {
        // Create new deck
        const { data, error } = await supabase
          .from('pitch_decks')
          .insert(deckData)
          .select();

        if (error) throw error;

        if (data && data.length > 0) {
          setDeckId(data[0].id);
          setShareUrl(`${window.location.origin}/pitch-deck/${data[0].id}`);
        }
      }

      // Show temporary success indicator
      setIsSaving(false);
      alert('Deck saved successfully!');
    } catch (error) {
      console.error('Error saving deck:', error);
      setIsSaving(false);
      alert('Failed to save deck. Please try again.');
    }
  };

  const handleNew = () => {
    if (confirm('Create a new pitch deck? Any unsaved changes will be lost.')) {
      setDeckId(null);
      setTitle('New Pitch Deck');
      setSlides([
        {
          id: '1',
          type: 'cover',
          title: 'Company Name',
          content: {
            text: 'Tagline goes here'
          }
        }
      ]);
      setCurrentSlide(0);
      setIsPublic(false);
    }
  };

  const addSlide = (type: Slide['type']) => {
    const newSlide: Slide = {
      id: crypto.randomUUID(),
      type,
      title: type === 'cover' ? 'Company Name' : 
             type === 'problem' ? 'The Problem' : 
             type === 'solution' ? 'Our Solution' : 
             type === 'market' ? 'Market Opportunity' : 
             type === 'business' ? 'Business Model' : 
             type === 'team' ? 'Our Team' : 'Custom Slide',
      content: {
        text: '',
        bullets: []
      }
    };

    setSlides([...slides, newSlide]);
    setCurrentSlide(slides.length);
  };

  const updateSlide = (index: number, updates: Partial<Slide>) => {
    const updatedSlides = [...slides];
    updatedSlides[index] = { ...updatedSlides[index], ...updates };
    setSlides(updatedSlides);
  };

  const deleteSlide = (index: number) => {
    if (slides.length <= 1) {
      alert('Cannot delete the only slide');
      return;
    }
    
    if (confirm('Delete this slide?')) {
      const updatedSlides = slides.filter((_, i) => i !== index);
      setSlides(updatedSlides);
      
      if (currentSlide >= updatedSlides.length) {
        setCurrentSlide(updatedSlides.length - 1);
      }
    }
  };

  const handleExport = async () => {
    try {
      const presentationId = await createGoogleSlides(title, slides);
      alert(`Presentation created! ID: ${presentationId}`);
    } catch (error) {
      console.error('Error exporting to Google Slides:', error);
      alert('Failed to export to Google Slides. Please try again.');
    }
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(shareUrl);
    alert('Link copied to clipboard!');
  };

  const handleGeneratePitchDeck = async () => {
    try {
      setIsGenerating(true);
      
      const result = await generatePitchDeck(businessInfo);
      
      if (result && result.slides) {
        setSlides(result.slides);
        setTitle(`${businessInfo.companyName} Pitch Deck`);
        setCurrentSlide(0);
        setShowGenerateDialog(false);
      }
    } catch (error) {
      console.error('Error generating pitch deck:', error);
      alert('Failed to generate pitch deck. Please try again.');
    } finally {
      setIsGenerating(false);
    }
  };

  const currentSlideData = slides[currentSlide];

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center">
            <Link
              to="/idea-hub"
              className="mr-4 p-2 text-gray-500 hover:text-gray-700 rounded-full hover:bg-gray-100"
            >
              <ArrowLeft className="h-5 w-5" />
            </Link>
            <div>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="text-2xl font-semibold text-gray-900 border-none focus:ring-0 p-0 bg-transparent"
                placeholder="Pitch Deck Title"
              />
            </div>
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => setShowGenerateDialog(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
            >
              <Sparkles className="h-4 w-4 mr-2" />
              AI Generate
            </button>
            <button
              onClick={handleNew}
              className="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              <Plus className="h-4 w-4 mr-2" />
              New
            </button>
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700"
            >
              {isSaving ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <Save className="h-4 w-4 mr-2" />
              )}
              Save
            </button>
            <button
              onClick={handleExport}
              className="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              <Presentation className="h-4 w-4 mr-2" />
              Export
            </button>
            <button
              onClick={() => setShowShareDialog(true)}
              className="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              <Share2 className="h-4 w-4 mr-2" />
              Share
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex mt-6">
          {/* Slide Thumbnails */}
          <div className="w-64 pr-6 space-y-2 overflow-y-auto max-h-[calc(100vh-10rem)]">
            {slides.map((slide, index) => (
              <div
                key={slide.id}
                className={`p-2 border rounded-md cursor-pointer ${
                  index === currentSlide
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-gray-200 hover:bg-gray-50'
                }`}
                onClick={() => setCurrentSlide(index)}
              >
                <div className="text-xs font-medium text-gray-500 mb-1">
                  Slide {index + 1}
                </div>
                <div className="text-sm font-medium truncate">{slide.title}</div>
              </div>
            ))}
            <button
              onClick={() => addSlide('custom')}
              className="w-full flex items-center justify-center p-2 border border-dashed border-gray-300 rounded-md text-gray-500 hover:text-gray-700 hover:border-gray-400"
            >
              <Plus className="h-4 w-4 mr-1" />
              Add Slide
            </button>
          </div>

          {/* Current Slide Editor */}
          <div className="flex-1 border rounded-lg p-6 bg-white shadow-sm">
            <div className="flex justify-between mb-4">
              <div className="space-x-2">
                <select
                  value={currentSlideData.type}
                  onChange={(e) => updateSlide(currentSlide, { type: e.target.value as Slide['type'] })}
                  className="rounded-md border-gray-300 text-sm"
                >
                  <option value="cover">Cover Slide</option>
                  <option value="problem">Problem Slide</option>
                  <option value="solution">Solution Slide</option>
                  <option value="market">Market Slide</option>
                  <option value="business">Business Model</option>
                  <option value="team">Team Slide</option>
                  <option value="custom">Custom Slide</option>
                </select>
                <button 
                  onClick={() => deleteSlide(currentSlide)}
                  className="text-red-600 hover:text-red-800 text-sm"
                >
                  Delete Slide
                </button>
              </div>
              <div className="flex items-center space-x-2">
                <button
                  disabled={currentSlide === 0}
                  onClick={() => setCurrentSlide(currentSlide - 1)}
                  className={`p-1 rounded-full ${
                    currentSlide === 0
                      ? 'text-gray-300 cursor-not-allowed'
                      : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <ChevronLeft className="h-5 w-5" />
                </button>
                <span className="text-sm text-gray-500">
                  {currentSlide + 1} / {slides.length}
                </span>
                <button
                  disabled={currentSlide === slides.length - 1}
                  onClick={() => setCurrentSlide(currentSlide + 1)}
                  className={`p-1 rounded-full ${
                    currentSlide === slides.length - 1
                      ? 'text-gray-300 cursor-not-allowed'
                      : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <ChevronRight className="h-5 w-5" />
                </button>
              </div>
            </div>

            <div className="mb-4">
              <label htmlFor="slide-title" className="block text-sm font-medium text-gray-700 mb-1">
                Slide Title
              </label>
              <input
                id="slide-title"
                type="text"
                value={currentSlideData.title}
                onChange={(e) => updateSlide(currentSlide, { title: e.target.value })}
                className="w-full rounded-md border-gray-300"
              />
            </div>

            <div className="mb-4">
              <label htmlFor="slide-text" className="block text-sm font-medium text-gray-700 mb-1">
                Main Text
              </label>
              <textarea
                id="slide-text"
                value={currentSlideData.content.text || ''}
                onChange={(e) => 
                  updateSlide(currentSlide, { 
                    content: { ...currentSlideData.content, text: e.target.value } 
                  })
                }
                rows={3}
                className="w-full rounded-md border-gray-300"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Bullet Points
              </label>
              {currentSlideData.content.bullets?.map((bullet, idx) => (
                <div key={idx} className="flex mb-2">
                  <input
                    type="text"
                    value={bullet}
                    onChange={(e) => {
                      const newBullets = [...(currentSlideData.content.bullets || [])];
                      newBullets[idx] = e.target.value;
                      updateSlide(currentSlide, { 
                        content: { ...currentSlideData.content, bullets: newBullets } 
                      });
                    }}
                    className="flex-1 rounded-md border-gray-300 text-sm"
                  />
                  <button
                    onClick={() => {
                      const newBullets = (currentSlideData.content.bullets || []).filter((_, i) => i !== idx);
                      updateSlide(currentSlide, { 
                        content: { ...currentSlideData.content, bullets: newBullets } 
                      });
                    }}
                    className="ml-2 text-red-500 hover:text-red-700"
                  >
                    Remove
                  </button>
                </div>
              ))}
              <button
                onClick={() => {
                  const newBullets = [...(currentSlideData.content.bullets || []), ''];
                  updateSlide(currentSlide, { 
                    content: { ...currentSlideData.content, bullets: newBullets } 
                  });
                }}
                className="inline-flex items-center text-sm text-indigo-600 hover:text-indigo-800"
              >
                <Plus className="h-3 w-3 mr-1" />
                Add Bullet Point
              </button>
            </div>

            {/* Image URL Input */}
            <div>
              <label htmlFor="slide-image" className="block text-sm font-medium text-gray-700 mb-1">
                Image URL (optional)
              </label>
              <input
                id="slide-image"
                type="text"
                value={currentSlideData.content.image || ''}
                onChange={(e) => 
                  updateSlide(currentSlide, { 
                    content: { ...currentSlideData.content, image: e.target.value } 
                  })
                }
                placeholder="https://example.com/image.jpg"
                className="w-full rounded-md border-gray-300 text-sm"
              />
              {currentSlideData.content.image && (
                <div className="mt-2 p-2 border rounded-md max-w-md max-h-40 overflow-hidden">
                  <img 
                    src={currentSlideData.content.image} 
                    alt="Slide preview" 
                    className="object-contain w-full"
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* AI Generation Dialog */}
      <Dialog.Root open={showGenerateDialog} onOpenChange={setShowGenerateDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <Dialog.Title className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <Sparkles className="h-5 w-5 mr-2 text-indigo-500" />
              Generate AI Pitch Deck
            </Dialog.Title>
            
            <div className="space-y-4">
              <p className="text-sm text-gray-500">
                Fill in the details below and our AI will generate a professional pitch deck for you.
              </p>
              
              <div className="grid grid-cols-1 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Company Name
                  </label>
                  <input
                    type="text"
                    value={businessInfo.companyName}
                    onChange={(e) => setBusinessInfo({...businessInfo, companyName: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Tagline
                  </label>
                  <input
                    type="text"
                    value={businessInfo.tagline}
                    onChange={(e) => setBusinessInfo({...businessInfo, tagline: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    placeholder="A short, memorable tagline for your company"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Problem
                  </label>
                  <textarea
                    value={businessInfo.problem}
                    onChange={(e) => setBusinessInfo({...businessInfo, problem: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Describe the problem you're solving (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Solution
                  </label>
                  <textarea
                    value={businessInfo.solution}
                    onChange={(e) => setBusinessInfo({...businessInfo, solution: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Describe your solution (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Market
                  </label>
                  <textarea
                    value={businessInfo.market}
                    onChange={(e) => setBusinessInfo({...businessInfo, market: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Describe your target market and size (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Business Model
                  </label>
                  <textarea
                    value={businessInfo.businessModel}
                    onChange={(e) => setBusinessInfo({...businessInfo, businessModel: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="How will you make money? (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Competition
                  </label>
                  <textarea
                    value={businessInfo.competition}
                    onChange={(e) => setBusinessInfo({...businessInfo, competition: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Who are your competitors? (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Team
                  </label>
                  <textarea
                    value={businessInfo.teamInfo}
                    onChange={(e) => setBusinessInfo({...businessInfo, teamInfo: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Describe your team and their expertise (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Financials
                  </label>
                  <textarea
                    value={businessInfo.financials}
                    onChange={(e) => setBusinessInfo({...businessInfo, financials: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    rows={3}
                    placeholder="Key financial projections (one point per line)"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Investment Ask (Optional)
                  </label>
                  <input
                    type="text"
                    value={businessInfo.askAmount || ''}
                    onChange={(e) => setBusinessInfo({...businessInfo, askAmount: e.target.value})}
                    className="w-full rounded-md border-gray-300 text-sm"
                    placeholder="e.g. $500K"
                  />
                </div>
              </div>
            </div>
            
            <div className="mt-6 flex justify-end space-x-3">
              <Dialog.Close asChild>
                <button className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md">
                  Cancel
                </button>
              </Dialog.Close>
              <button
                onClick={handleGeneratePitchDeck}
                disabled={isGenerating || !businessInfo.companyName || !businessInfo.problem || !businessInfo.solution}
                className={`inline-flex items-center px-4 py-2 text-sm font-medium rounded-md text-white ${
                  isGenerating || !businessInfo.companyName || !businessInfo.problem || !businessInfo.solution
                    ? 'bg-indigo-400 cursor-not-allowed'
                    : 'bg-indigo-600 hover:bg-indigo-700'
                }`}
              >
                {isGenerating ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Generating...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-4 w-4 mr-2" />
                    Generate Pitch Deck
                  </>
                )}
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Share Dialog */}
      <Dialog.Root open={showShareDialog} onOpenChange={setShowShareDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-white rounded-lg p-6 w-full max-w-md">
            <Dialog.Title className="text-lg font-semibold text-gray-900 mb-4">
              Share Pitch Deck
            </Dialog.Title>
            
            <div className="space-y-4">
              <div className="flex items-center">
                <input 
                  type="checkbox" 
                  id="is-public" 
                  checked={isPublic}
                  onChange={(e) => setIsPublic(e.target.checked)}
                  className="h-4 w-4 text-indigo-600 border-gray-300 rounded mr-2"
                />
                <label htmlFor="is-public" className="text-sm text-gray-700">
                  Make pitch deck public
                </label>
              </div>
              
              {isPublic && (
                <div className="bg-gray-50 p-3 rounded-md">
                  <div className="flex items-center text-sm mb-2">
                    <Globe className="h-4 w-4 text-gray-500 mr-2" />
                    <span className="text-gray-500">Anyone with the link can view</span>
                  </div>
                  <div className="flex">
                    <input
                      type="text"
                      value={shareUrl}
                      readOnly
                      className="flex-1 rounded-l-md border-r-0 border-gray-300 text-sm text-gray-600"
                    />
                    <button
                      onClick={handleCopyLink}
                      className="flex items-center px-3 py-2 border border-l-0 border-gray-300 rounded-r-md hover:bg-gray-50"
                    >
                      <Copy className="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>
              )}
              
              {!isPublic && (
                <div className="bg-gray-50 p-3 rounded-md flex items-center text-sm">
                  <Lock className="h-4 w-4 text-gray-500 mr-2" />
                  <span className="text-gray-500">This pitch deck is private</span>
                </div>
              )}
            </div>
            
            <div className="mt-6 flex justify-end">
              <Dialog.Close asChild>
                <button className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md">
                  Close
                </button>
              </Dialog.Close>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}